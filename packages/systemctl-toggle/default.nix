{
  pkgs,
  systemd,
  ...
}:
pkgs.writeShellApplication {
  name = "systemctl-toggle";
  runtimeInputs = [systemd];
  text = builtins.readFile ./systemctl-toggle.sh;
}
