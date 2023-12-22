{config, pkgs, lib, ...}: with lib; let
  cfg = config.copper.chroma;
in {
  options = {
    copper.chroma.fish.enable = mkEnableOption "Chroma integration for fish" // { default = true; };
  };

  config = mkMerge [
    ({
      copper.chroma.programs.fish = {
        themeOptions.theme = {
          file = mkOption {
            type = with types; nullOr path;
            example = literalExpression ''./Catppuccin-Latte.fish'';
            description = ''
              The fish theme file as a path. If left blank, you can only use
              built-in themes or themes that are otherwise installed.
            '';
          };

          name = mkOption {
            type = types.str;
            example = literalExpression ''Catppuccino-Latte'';
            description = ''
              The name of the theme. If left blank, the name of the file will
              be used.
            '';
          };
        };

        activationCommand = { name, opts }: ''
          yes | env ${config.programs.fish.package}/bin/fish -c 'fish_config theme save "${opts.theme.name}"' 2>/dev/null
        '';
      };
    })
    (mkIf (cfg.enable && cfg.fish.enable) {
      xdg.configFile = mkMerge (
        map
        ({ name, value }: {
          "fish/themes/${value.fish.theme.name}.theme".source = value.fish.theme.file;
        })
        (filter (e: e.value.fish.theme.file != null) (attrsToList cfg.themes))
      );
    })
  ];
}
