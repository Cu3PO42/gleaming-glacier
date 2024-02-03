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
  self,
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
        self.swimctl
        self.chromactl
        self.nailgun
      ];
      checkPhase = "";
      text = builtins.readFile "${./src}/${f}";
    }) (builtins.attrNames (builtins.readDir ./src));
}
