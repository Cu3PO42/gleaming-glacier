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
    /// A keymap has been activated. This also cancels the prior submap.
    Activate(ActivateArgs),
    /// A keybind was used in the current submap, but it is not deactivated.
    Use,
    /// We have returned to the root map.
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