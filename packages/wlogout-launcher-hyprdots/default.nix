{
  pkgs,
  procps,
  envsubst,
  dconf,
  ...
}:
pkgs.writeShellApplication {
  name = "wlogout-launcher-hyprland";
  runtimeInputs = [procps envsubst dconf];
  text = builtins.readFile ./wlogout-launcher-hyprdots.sh;
}
