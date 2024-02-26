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
  lib,
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

      meta = with lib; {
        description = "A launcher for Rofi from Hyprdots.";
        homepage = "https://github.com/prasanthrangan/hyprdots";
        license = licenses.gpl3Only;
        maintainers = ["Cu3PO42"];
        platforms = platforms.linux;
      };
    }) (builtins.attrNames (builtins.readDir ./src));
}
