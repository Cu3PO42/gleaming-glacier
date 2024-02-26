use interprocess::local_socket::{LocalSocketName, ToLocalSocketName};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug)]
pub enum Command {
    MapActivated(String),
    BindUsed,
    MapExit,
}

#[cfg(windows)]
pub fn socket_path() -> std::io::Result<&'static str> {
    r"\\.\pipe\maestro"
}

#[cfg(target_os = "macos")]
pub fn socket_path() -> std::io::Result<std::path::PathBuf> {
    let mut home = std::env::home_dir().ok_or_else(|| std::io::Error::new(std::io::ErrorKind::NotFound, "HOME not set"))?;
    home.push("Library/Application Support/maestro");
    std::fs::create_dir_all(&home)?;
    home.push("maestro.sock");
    Ok(home)
}

#[cfg(target_os = "linux")]
pub fn socket_path() -> std::io::Result<std::path::PathBuf> {
    let base_dirs = xdg::BaseDirectories::with_prefix("maestro")?;
    let res = base_dirs.place_runtime_file("maestro.sock");
    return res;

}