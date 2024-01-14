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
    };

    programs.waybar.style = mkIf (cfg.enable && cfg.waybar.enable) ''
      @import "${config.copper.chroma.themeDirectory}/active/waybar/theme.css";
    '';
  };
}
