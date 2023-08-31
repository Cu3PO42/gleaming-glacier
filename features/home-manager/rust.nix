{pkgs, ...}: {
  home.sessionPath = ["$HOME/.cargo/bin"];
  home.packages = with pkgs; [rustup];
}
