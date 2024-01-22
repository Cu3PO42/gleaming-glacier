{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.copper.chroma;

  inherit (import ../../../../lib/types.nix {inherit lib;}) colorType;
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
      themeOptions = {
        colorOverrides = mkOption {
          type = with types; attrsOf colorType;
          default = {};
          description = ''
            Color overrides to apply to the palette-generated theme.
          '';
        };
      };

      themeConfig = {config, opts, ...}: {
        file."theme.rasi" = {
          required = true;

          source = mkDefault (opts.palette.generateDynamic {
            template = ./rofi.rasi.dyn;
            paletteOverrides = config.colorOverrides;
          });
        };

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

      programs.rofi.theme = "${cfg.themeDirectory}/active/rofi/theme.rasi";
      programs.rofi.imports = ["${cfg.themeDirectory}/active/rofi/config.rasi"];
    })
  ];
}
