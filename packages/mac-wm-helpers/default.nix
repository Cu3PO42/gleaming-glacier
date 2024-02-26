{writeShellApplication, lib, symlinkJoin, callPackage, ...}: let
  mkShellHelper = name: description: writeShellApplication {
    inherit name;
    text = builtins.readFile ./${name}.sh;

    meta = with lib; {
      inherit description;
      homepage = "https://github.com/Cu3PO42/gleaming-glacier";
      license = licenses.gpl3Plus;
      maintainers = ["Cu3PO42"];
      platforms = platforms.darwin;
    };
  };
in symlinkJoin {
  name = "mac-wm-helpers";
  paths = [
    (mkShellHelper "spacectl" "A utility to change the active space in macOS using native keybinds.")
    (mkShellHelper "open-iterm-window" "A utility to open a new iTerm window.")
    (callPackage ./keybind-helper {})
  ];
}