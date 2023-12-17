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
      default = true;
      example = false;
      description = ''
        Whether to enable waybar theming as part of Chroma.
      '';
    };
  };

  config = {
    copper.chroma.programs.waybar = {
      reloadCommand = ''
        ${pkgs.procps}/bin/pkill -u $USER -USR2 waybar || true
      '';
    };

    programs.waybar.style = mkIf (cfg.enable && cfg.waybar.enable) ''
      @import "${config.copper.chroma.themeFolder}/active/waybar/theme.css";
      @import "${config.xdg.configHome}/waybar/style.mine.css";
    '';
  };
}
