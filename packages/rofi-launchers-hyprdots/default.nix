{
  symlinkJoin,
  writeShellApplication,
  hyprland,
  gnused,
  gawk,
  rofi-wayland,
  dunst,
  dconf,
  cliphist,
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
        hyprland
        gnused
        gawk
        rofi-wayland
        dunst
        dconf
        cliphist
        inputs.self.outputs.packages.${pkgs.system}.swimctl
        inputs.self.outputs.packages.${pkgs.system}.chromactl
        inputs.self.outputs.packages.${pkgs.system}.nailgun
      ];
      checkPhase = "";
      text = builtins.readFile "${./src}/${f}";
    }) (builtins.attrNames (builtins.readDir ./src));
}
