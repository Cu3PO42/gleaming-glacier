{
  config,
  lib,
  pkgs,
  origin,
  ...
}:
with lib; let
  cfg = config.copper.chroma;
  
  inherit (origin.self.lib.types) colorType;
in {
  options = {
    copper.chroma.waybar.enable = mkOption {
      type = types.bool;
      default = config.programs.waybar.enable;
      example = false;
      description = ''
        Whether to enable waybar theming as part of Chroma.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = !(cfg.enable && cfg.waybar.enable) || config.programs.waybar.enable;
        message = "Chroma integration for Waybar requires base waybar module.";
      }
    ];

    copper.chroma.programs.waybar = {
      reloadCommand = ''
        ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
      '';

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
        file."theme.css" = {
          required = true;

          source = mkDefault (opts.palette.generateDynamic {
            template = ./waybar.css.dyn;
            paletteOverrides = config.colorOverrides;
          });
        };
      };
    };

    programs.waybar.style = mkIf (cfg.enable && cfg.waybar.enable) ''
      @import "${config.copper.chroma.themeDirectory}/active/waybar/theme.css";
    '';
  };
}
