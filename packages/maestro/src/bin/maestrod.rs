use std::{io::Read, process::Command, sync::{atomic::{AtomicBool, Ordering}, Arc, Mutex, Condvar}, thread, time::Duration};

use interprocess::local_socket::LocalSocketListener;
use anyhow::Context;

#[derive(serde::Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct Config {
    cancel_command: String,
    help_command: Option<String>,
    keymap_timeout: u64,
    help_timeout: u64,
}

fn run_command(command: &str) -> anyhow::Result<()> {
    let _ = Command::new("/usr/bin/env")
        .arg("sh")
        .arg("-c")
        .arg(command)
        .spawn().context("spawning command")?
        .wait();
    Ok(())
}

struct ServerConfig {
    keymap_timeout: u64,
    help_timeout: u64,
    help_command: Option<&'static str>,
    cancel_command: &'static str,
}

#[derive(Debug, Default)]
struct ServerState {
    keymap: String,
    cancel_flag: Mutex<bool>,
    abort_flag: Mutex<bool>,
    abort_cond: Condvar,
    help_active: Mutex<bool>,
}

impl ServerState {
    fn new(keymap: String) -> Self {
        Self {
            keymap,
            ..Default::default()
        }
    }
}

struct Server {
    config: ServerConfig,
    state: Option<Arc<ServerState>>,
}

impl Server {
    fn new(config: ServerConfig) -> Self {
        Self {
            config,
            state: None,
        }
    }

    fn abort_running(&mut self) {
        if let Some(state) = self.state.take() {
            *state.cancel_flag.lock().unwrap() = true;
            *state.abort_flag.lock().unwrap() = true;
            state.abort_cond.notify_all();
        }
    }

    fn dispatch(&mut self, cmd: maestro::Command) -> anyhow::Result<()> {
        use maestro::Command;
        match cmd {
            Command::MapActivated(map_name) => {
                println!("Map activated: {}", map_name);

                let in_help = self.state.as_ref().is_some_and(|state| *state.help_active.lock().unwrap());

                self.abort_running();
                let state = Arc::new(ServerState::new(map_name));
                *state.help_active.lock().unwrap() = in_help;
                self.state = Some(state.clone());

                // We need to copy these values because otherwise self would be moved.
                let help_timeout = self.config.help_timeout;
                let keymap_timeout = self.config.keymap_timeout;
                let help_command = self.config.help_command;
                let cancel_command = self.config.cancel_command;

                thread::spawn(move || {
                    if let Some(help_command) = help_command {
                        if !in_help {
                            thread::sleep(Duration::from_secs(help_timeout));
                            if *state.cancel_flag.lock().unwrap() {
                                return;
                            }
                            println!("Help timeout exceeded, running help command for map: {}", state.keymap);
                        }

                        *state.help_active.lock().unwrap() = true;
                        let mut proc = std::process::Command::new("/usr/bin/env")
                            .arg("sh")
                            .arg("-c")
                            .arg(help_command)
                            .env("KEYMAP", &state.keymap)
                            .spawn()
                            .unwrap();

                        if keymap_timeout > 0 {
                            let child_state = state.clone();
                            thread::spawn(move || {
                                let waited_before = if in_help { 0 } else { help_timeout };
                                thread::sleep(Duration::from_secs(keymap_timeout - waited_before));

                                *child_state.abort_flag.lock().unwrap() = true;
                                child_state.abort_cond.notify_all();

                                if !*child_state.cancel_flag.lock().unwrap() {
                                    run_command(cancel_command).unwrap();
                                }
                            });
                        }

                        let mut close = state.abort_flag.lock().unwrap();
                        while !*close {
                            close = state.abort_cond.wait(close).unwrap();
                        }

                        *state.help_active.lock().unwrap() = false;
                        // If we get to this point, one of two things must have happened:
                        // - We have reached the keymap timeout,
                        // - The user has switched maps or used a bind.
                        // In either case we're done here and just need to close the help window.
                        #[cfg(unix)]
                        {
                            // We cannot use the normal kill() method here because it sends a
                            // SIGKILL and thus leaves no chance to clean up child proecesses
                            // as well.
                            let pid = nix::unistd::Pid::from_raw(proc.id() as i32);
                            nix::sys::signal::kill(pid, nix::sys::signal::SIGTERM).unwrap();
                        }
                        #[cfg(windows)]
                        {
                            // TODO: this may or may not be fine
                            proc.kill().unwrap();
                        }
                        // We need to make sure to read the exit status to avoid zombies.
                        let _ = proc.wait();
                    } else if keymap_timeout > 0 {
                        thread::sleep(Duration::from_secs(keymap_timeout));
                        if *state.cancel_flag.lock().unwrap() {
                            return;
                        }
                        run_command(cancel_command).unwrap();
                    }
                });
            }
            Command::BindUsed => {
                println!("Bind used");
                if let Some(state) = &self.state {
                    // Includes abort.
                    self.dispatch(Command::MapActivated(state.keymap.clone()))?;
                } else {
                    self.abort_running();
                }
            },
            Command::MapExit => {
                println!("Map exit");
                self.abort_running();
            }
        }
        Ok(())
    }
}

fn main() -> anyhow::Result<()> {
    let base_dirs = xdg::BaseDirectories::with_prefix("maestro")?;
    let config_path = base_dirs.get_config_file("config.json");
    let config_contents = std::fs::read_to_string(config_path).context("reading config file")?;
    let config: Config = serde_json::from_str(&config_contents).context("parsing config file")?;

    let server_config = ServerConfig {
        keymap_timeout: config.keymap_timeout,
        cancel_command: Box::leak(config.cancel_command.into_boxed_str()),

        help_timeout: config.help_timeout,
        // If the timeout is 0 or greater than the keymap timeout, the help function never comes into play.
        // Set it to None here to reduce testing in other parts of the code.
        help_command: (config.help_timeout > 0 && (config.help_timeout < config.keymap_timeout || config.keymap_timeout == 0))
            .then(|| config.help_command.map(|v| Box::leak(v.into_boxed_str()) as &str)).flatten(),
    };

    let mut server = Server::new(server_config);

    let socket_path = maestro::socket_path()?;
    // If we are using Unix domain sockets, remove the existing socket file because binding will
    // always create a new file.
    #[cfg(unix)]
    let _ = std::fs::remove_file(&socket_path);
    let listener = LocalSocketListener::bind(socket_path).context("opening socket")?;

    let mut buf = Vec::new();
    loop {
        {
            buf.truncate(0);
            let mut stream = listener.accept().context("accepting connection")?;
            stream.read_to_end(&mut buf).context("reading command")?;
        }
        let text = std::str::from_utf8(&buf).context("interpreting message as text")?;
        let cmd: maestro::Command = serde_json::from_str(text).with_context(|| format!("Message invalid: {}", text))?;
        server.dispatch(cmd).context("executing action")?;
    }
}