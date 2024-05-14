{
  symlinkJoin,
  writeShellApplication,
  gnused,
  gawk,
  dunst,
  brightnessctl,
  jq,
  pamixer,
  swappy,
  libnotify,
  procps,
  dbus,
  inputs,
  lib,
  ...
}:
symlinkJoin {
  name = "misc-scripts-hyprdots";
  paths = builtins.map (f:
    writeShellApplication {
      name = f;
      runtimeInputs = [
        dunst
        brightnessctl
        inputs.hyprland.packages.default
        jq
        gnused
        gawk
        pamixer
        inputs.hypr-contrib.packages.grimblast
        swappy
        procps
        libnotify
        dbus
      ];
      checkPhase = "";
      text = builtins.readFile "${./src}/${f}";

      meta = with lib; {
        description = "The ${f} script from Hyprdots.";
        homepage = "https://github.com/prasanthrangan/hyprdots";
        license = licenses.gpl3Only;
        maintainers = ["Cu3PO42"];
        platforms = platforms.linux;
      };
    }) (builtins.attrNames (builtins.readDir ./src));
}
