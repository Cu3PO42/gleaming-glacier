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
      default = config.programs.kitty.enable;
      example = false;
      description = ''
        Whether to enable Kitty theming as part of Chroma.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = !(cfg.enable && cfg.kitty.enable) || config.programs.kitty.enable;
        message = "Chroma Kitty theming requires Kitty to be enabled.";
      }
    ];
    # TODO: set the font to the monospace font?

    copper.chroma.programs.kitty = {
      reloadCommand = "${pkgs.procps}/bin/pkill -USR1 -u $USER kitty || true";
    };

    programs.kitty.settings.include = mkIf (cfg.enable && cfg.kitty.enable) "${config.copper.chroma.themeDirectory}/active/kitty/theme.conf";
  };
}
