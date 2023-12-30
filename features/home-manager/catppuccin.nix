{
  pkgs,
  config,
  lib,
  ...
}: let
in {
  copper.chroma = {
    enable = true;
    themes.Catppuccin-Mocha = lib.mkDefault (import ../../themes/Catppuccin-Mocha/default.nix {
      inherit pkgs config lib;
    });
    initialTheme = lib.mkDefault "Catppuccin-Mocha";
  };
}
