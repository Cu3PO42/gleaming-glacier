{
  pkgs,
  envsubst,
  dconf,
  gawk,
  gnused,
  hyprland,
  systemd,
  procps,
  ...
}:
pkgs.writeShellApplication {
  name = "waybar-confgen-hyprdots";
  runtimeInputs = [
    envsubst
    dconf
    gawk
    gnused
    hyprland
    systemd
    procps
  ];
  text = builtins.readFile ./wbarconfgen.sh;
  checkPhase = "";
}
