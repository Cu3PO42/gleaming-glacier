{
  pkgs,
  procps,
  envsubst,
  dconf,
  lib,
  ...
}:
pkgs.writeShellApplication {
  name = "wlogout-launcher-hyprland";
  runtimeInputs = [procps envsubst dconf];
  text = builtins.readFile ./wlogout-launcher-hyprdots.sh;

  meta = with lib; {
    description = "The tool to start wlogout from Hyprdots.";
    homepage = "https://github.com/prasanthrangan/hyprdots";
    license = licenses.gpl3Only;
    maintainers = ["Cu3PO42"];
    platforms = platforms.linux;
  };
}
