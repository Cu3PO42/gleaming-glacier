{
  pkgs,
  systemd,
  lib,
  ...
}:
pkgs.writeShellApplication {
  name = "systemctl-toggle";
  runtimeInputs = [systemd];
  text = builtins.readFile ./systemctl-toggle.sh;

  meta = with lib; {
    description = "A trivial helper to toglge the state of a systemd service";
    homepage = "https://github.com/Cu3PO42/gleaming-glacier";
    license = licenses.gpl3Plus;
    maintainers = ["Cu3PO42"];
    platforms = platforms.linux;
  };
}
