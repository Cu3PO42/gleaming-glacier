{writeShellApplication, lib, symlinkJoin, ...}: let
  mkShellHelper = name: (writeShellApplication {
    inherit name;
    text = builtins.readFile ./${name}.sh;
  }).overrideAttrs (old: {
    meta = (old.meta or {}) // {
      platforms = lib.platforms.darwin;
    };
  });
in symlinkJoin {
  name = "mac-wm-helpers";
  paths = [
    (mkShellHelper "spacectl")
    (mkShellHelper "open-iterm-window")
  ];
}