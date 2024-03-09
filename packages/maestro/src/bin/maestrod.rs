use std::io::Read;
use std::process::Command;
use std::sync::{Arc, Mutex, Condvar};
use std::thread;
use std::time::Duration;

use interprocess::local_socket::LocalSocketListener;
use anyhow::Context;

#[derive(serde::Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct Config {
    /// The command to execute to exit the current submap.
    cancel_keymap_command: String,
    /// The command to execute to show the help window for the current submap.
    /// This may either exit immediately or run while the window stays open.
    help_command: Option<String>,
    /// The command to execute to close the help window for the current submap.
    /// This is useful in particular when the command to spawn the help window
    /// is a short-running process.
    cancel_help_command: Option<String>,
    /// The time after which to automatically leave the current submap.
    keymap_timeout: u64,
    /// The time after which to automatically show the help window for the
    /// current submap.
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

/// A version of `Config` with 'static lifetimes for use in the server.
struct ServerConfig {
    keymap_timeout: u64,
    help_timeout: u64,
    help_command: Option<&'static str>,
    cancel_help_command: Option<&'static str>,
    cancel_keymap_command: &'static str,
}

#[derive(Debug, Default, Clone, Copy)]
struct StateFlags {
    /// Whether any remaining actions on the current thread or threads should
    /// be canceled. This is used when an operation is overriden by a new one.
    stop_thread: bool,
    /// This flag indicates that the help window should be closed.
    close_help: bool,
    /// This variable indicates whether the help window was opened for `keymap`.
    help_active: bool,
}

#[derive(Debug, Default)]
struct ServerState {
    /// The keymap that was activated.
    keymap: String,
    /// These flags indicate how the current thread should behave.
    flags: Mutex<StateFlags>,
    /// This condition variable is used to notify other threads that some
    /// flag has been set.
    cond: Condvar,
}

impl ServerState {
    fn new(keymap: String, help_active: bool) -> Self {
        Self {
            keymap,
            flags: Mutex::new(StateFlags {
                stop_thread: false,
                close_help: false,
                help_active: help_active,
            }),
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
            let mut flags = state.flags.lock().unwrap();
            flags.stop_thread = true;
            flags.close_help = true;
            flags.help_active = false;
            state.cond.notify_all();
        }
    }

    fn dispatch(&mut self, cmd: maestro::Command) -> anyhow::Result<()> {
        use maestro::Command;
        match cmd {
            Command::MapActivated(map_name) => {
                println!("Map activated: {}", map_name);


                let mut in_help = false;
                if let Some(state) = &self.state {
                    let mut flags = state.flags.lock().unwrap();
                    flags.stop_thread = true;
                    in_help = flags.help_active;
                }

                let state = Arc::new(ServerState::new(map_name, in_help));
                self.state = Some(state.clone());

                // We need to copy these values because otherwise self would be moved.
                let help_timeout = self.config.help_timeout;
                let keymap_timeout = self.config.keymap_timeout;
                let help_command = self.config.help_command;
                let cancel_help_command = self.config.cancel_help_command;
                let cancel_keymap_command = self.config.cancel_keymap_command;

                thread::spawn(move || {
                    if let Some(help_command) = help_command {
                        let mut flags;
                        if !in_help {
                            thread::sleep(Duration::from_secs(help_timeout));
                            flags = state.flags.lock().unwrap();
                            if flags.stop_thread {
                                return;
                            }

                            println!("Help timeout exceeded, running help command for map: {}", state.keymap);
                        } else {
                            flags = state.flags.lock().unwrap();
                        }

                        flags.help_active = true;
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
                                let mut flags = child_state.flags.lock().unwrap();
                                if !flags.stop_thread {
                                    return;
                                }

                                flags.close_help = true;
                                flags.help_active = false;
                                std::mem::drop(flags);
                                child_state.cond.notify_all();

                                run_command(cancel_keymap_command).unwrap();
                            });
                        }

                        while !(flags.stop_thread || flags.close_help) {
                            flags = state.cond.wait(flags).unwrap();
                        }
                        let flags = *flags;

                        // If we get to this point, one of two things must have happened:
                        // - We have reached the keymap timeout,
                        // - The user has switched maps or used a bind.
                        // In either case we're done here and just need to close the help window.
                        #[cfg(unix)]
                        {
                            // Even if the process is already dead, we can still send the signal.

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

                        if flags.close_help {
                            if let Some(cancel_help_command) = cancel_help_command {
                                run_command(cancel_help_command).unwrap();
                            }
                        }
                    } else if keymap_timeout > 0 {
                        thread::sleep(Duration::from_secs(keymap_timeout));
                        if state.flags.lock().unwrap().stop_thread {
                            return;
                        }
                        run_command(cancel_keymap_command).unwrap();
                    }
                });
            }
            Command::BindUsed => {
                println!("Bind used");
                if let Some(state) = &self.state {
                    // Includes abort.
                    self.dispatch(Command::MapActivated(state.keymap.clone()))?;
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
        cancel_keymap_command: Box::leak(config.cancel_keymap_command.into_boxed_str()),

        help_timeout: config.help_timeout,
        // If the timeout is 0 or greater than the keymap timeout, the help function never comes into play.
        // Set it to None here to reduce testing in other parts of the code.
        help_command: (config.help_timeout > 0 && (config.help_timeout < config.keymap_timeout || config.keymap_timeout == 0))
            .then(|| config.help_command.map(|v| Box::leak(v.into_boxed_str()) as &str)).flatten(),
        cancel_help_command: config.cancel_help_command.map(|v| Box::leak(v.into_boxed_str()) as &str),
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