{
  pkgs,
  envsubst,
  dconf,
  gawk,
  gnused,
  systemd,
  procps,
  lib,
  inputs,
  ...
}:
pkgs.writeShellApplication {
  name = "waybar-confgen-hyprdots";
  runtimeInputs = [
    envsubst
    dconf
    gawk
    gnused
    inputs.hyprland.packages.default
    systemd
    procps
  ];
  text = builtins.readFile ./wbarconfgen.sh;
  checkPhase = "";

  meta = with lib; {
    description = "The tool to generate a Waybar configuration from the DSL in Hyprdots.";
    homepage = "https://github.com/prasanthrangan/hyprdots";
    license = licenses.gpl3Only;
    maintainers = ["Cu3PO42"];
    platforms = platforms.linux;
  };
}
