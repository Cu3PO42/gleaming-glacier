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

struct Server {
    config: ServerConfig,

    current_keymap: Option<String>,
    cancel_flag: Option<Arc<AtomicBool>>,
    abort_help: Option<Arc<(Mutex<bool>, Condvar)>>,
}

impl Server {
    fn new(config: ServerConfig) -> Self {
        Self {
            config,

            cancel_flag: None,
            current_keymap: None,
            abort_help: None,
        }
    }

    fn abort_running(&mut self) {
        if let Some(f) = self.cancel_flag.take() {
            f.store(true, Ordering::Relaxed);
        }
        if let Some(abort_help) = self.abort_help.take() {
            *abort_help.0.lock().unwrap() = true;
            abort_help.1.notify_all();
        }
        self.current_keymap.take();
    }

    fn dispatch(&mut self, cmd: maestro::Command) -> anyhow::Result<()> {
        use maestro::Command;
        match cmd {
            Command::MapActivated(map_name) => {
                println!("Map activated: {}", map_name);

                self.abort_running();
                let cancel_flag = Arc::new(AtomicBool::new(false));
                let abort_help = Arc::new((Mutex::new(false), Condvar::new()));

                self.current_keymap = Some(map_name.clone());
                self.cancel_flag = Some(cancel_flag.clone());
                self.abort_help = Some(abort_help.clone());

                // We need to copy these values because otherwise self would be moved.
                let help_timeout = self.config.help_timeout;
                let keymap_timeout = self.config.keymap_timeout;
                let help_command = self.config.help_command;
                let cancel_command = self.config.cancel_command;

                thread::spawn(move || {
                    if let Some(help_command) = help_command {
                        thread::sleep(Duration::from_secs(help_timeout));
                        if cancel_flag.load(Ordering::Relaxed) {
                            return;
                        }

                        println!("Help timeout exceeded, running help command for map: {}", map_name);
                        let mut proc = std::process::Command::new("/usr/bin/env")
                            .arg("sh")
                            .arg("-c")
                            .arg(help_command)
                            .env("KEYMAP", &map_name)
                            .spawn()
                            .unwrap();

                        if keymap_timeout > 0 {
                            let child_abort_help = abort_help.clone();
                            thread::spawn(move || {
                                thread::sleep(Duration::from_secs(keymap_timeout - help_timeout));

                                *child_abort_help.0.lock().unwrap() = true;
                                child_abort_help.1.notify_all();

                                if !cancel_flag.load(Ordering::Relaxed) {
                                    run_command(cancel_command).unwrap();
                                }
                            });
                        }

                        let mut close = abort_help.0.lock().unwrap();
                        while !*close {
                            close = abort_help.1.wait(close).unwrap();
                        }

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
                        if cancel_flag.load(Ordering::Relaxed) {
                            return;
                        }
                        run_command(cancel_command).unwrap();
                    }
                });
            }
            Command::BindUsed => {
                println!("Bind used");
                let map_name = self.current_keymap.take();
                self.abort_running();
                if let Some(map_name) = map_name {
                    self.dispatch(Command::MapActivated(map_name))?;
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