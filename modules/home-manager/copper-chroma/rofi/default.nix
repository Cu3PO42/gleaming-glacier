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
      default = config.programs.rofi.enable;
      example = false;
      description = ''
        Whether to enable rofi theming as part of Chroma.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = !(cfg.enable && cfg.rofi.enable) || config.programs.rofi.enable;
        message = "Rofi Chroma integration only works when the base Rofi module is enabled.";
      }
      {
        assertion = !(cfg.enable && cfg.rofi.enable) || cfg.desktop.enable;
        message = "Rofi Chroma integration requires the desktop module";
      }
    ];

    copper.chroma.programs.rofi = {
      requiredFiles = ["theme.rasi"];

      themeConfig = {opts, ...}: {
        file."config.rasi".text = ''
          configuration {
            icon-theme: "${opts.desktop.iconTheme.name}";
          }
        '';
      };
    };
  };

  imports = [
    (mkIf (cfg.enable && cfg.rofi.enable) {
      copper.chroma.desktop.enable = true;

      programs.rofi.theme = "${cfg.themeFolder}/active/rofi/theme.rasi";
      programs.rofi.imports = ["${cfg.themeFolder}/active/rofi/config.rasi"];
    })
  ];
}
