{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.copper.chroma;
in {
  options = {
    copper.chroma.rofi.enable = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether to enable rofi theming as part of Chroma.
      '';
    };
  };

  config = {
    copper.chroma.programs.rofi = {
      requiredFiles = ["theme.rasi"];
    };
  };

  imports = [
    (mkIf (cfg.enable && cfg.rofi.enable) {
      programs.rofi.theme = "${cfg.themeFolder}/active/rofi/theme.rasi";
    })
  ];
}
