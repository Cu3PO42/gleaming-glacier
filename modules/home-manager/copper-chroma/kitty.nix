{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.copper.chroma;
in {
  options = {
    copper.chroma.kitty.enable = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether to enable Kitty theming as part of Chroma.
      '';
    };
  };

  config = {
    copper.chroma.programs.kitty = {
      reloadCommand = "${pkgs.procps}/bin/pkill -USR1 -u $USER kitty || true";
    };

    programs.kitty.settings.include = mkIf (cfg.enable && cfg.kitty.enable) "${config.copper.chroma.themeFolder}/active/kitty/theme.conf";
  };
}
