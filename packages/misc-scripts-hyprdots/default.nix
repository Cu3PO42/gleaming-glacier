{
  symlinkJoin,
  writeShellApplication,
  hyprland,
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
  pkgs,
  ...
}:
symlinkJoin {
  name = "rofi-launcher-hyprdots";
  paths = builtins.map (f:
    writeShellApplication {
      name = f;
      runtimeInputs = [
        dunst
        brightnessctl
        hyprland
        jq
        gnused
        gawk
        pamixer
        inputs.hypr-contrib.packages.${pkgs.system}.grimblast
        swappy
        procps
        libnotify
        dbus
      ];
      checkPhase = "";
      text = builtins.readFile "${./src}/${f}";
    }) (builtins.attrNames (builtins.readDir ./src));
}
