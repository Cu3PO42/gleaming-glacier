use std::io::Write;

use clap::{Parser, Subcommand};
use interprocess::local_socket::LocalSocketStream;

/// Maestro helps you remember your keybinds.
#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    #[clap(subcommand)]
    command: Command,
}

#[derive(Debug, Subcommand)]
enum Command {
    /// A keymap has been activated.
    /// 
    /// After a timeout, if no keybind is used, a help window will be shown.
    /// While any submap is active, the help window will stay open.
    /// If a fixed number of seconds pass without any key being pressed, the
    /// submap will be deactivated and the help window will be closed.
    Activate(ActivateArgs),
    /// A keybind was used in the current submap, but it is not deactivated.
    /// 
    /// If no help window is currently opened, no help window will be shown for the current submap.
    /// If a help window is currently open, it will stay open until the map is exited.
    Use,
    /// We have returned to the root map.
    /// 
    /// Closes any currently opened help window.
    Exit,
}

#[derive(Parser, Debug)]
struct ActivateArgs {
    #[arg()]
    map_name: String,
}

impl From<Command> for maestro::Command {
    fn from(command: Command) -> maestro::Command {
        match command {
            Command::Activate(activate_args) => maestro::Command::MapActivated(activate_args.map_name),
            Command::Use => maestro::Command::BindUsed,
            Command::Exit => maestro::Command::MapExit,
        }
    }
}

fn main() -> anyhow::Result<()> {
    let args = Args::parse();
    let command: maestro::Command = args.command.into();
    let mut stream = LocalSocketStream::connect(maestro::socket_path()?)?;
    stream.write_all(serde_json::to_string(&command)?.as_bytes())?;

    Ok(())
}