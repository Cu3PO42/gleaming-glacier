{config, pkgs, lib, ...}: with lib; let
  cfg = config.copper.chroma;

  tomlFormat = pkgs.formats.toml {};
in {
  options = {
    copper.chroma.starship.enable = mkEnableOption "Chroma integration for starship" // { default = config.programs.starship.enable; };
  };

  config = mkMerge [
    ({
      copper.chroma.programs.starship = {
        themeOptions = {
          palette.file = mkOption {
            type = with types; either str path;
            example = literalExpression ''
              (pkgs.fetchFromGitHub {
                owner = "catppuccin";
                repo = "starship";
                  rev = "3e3e54410c3189053f4da7a7043261361a1ed1bc";
                  hash = "sha256-soEBVlq3ULeiZFAdQYMRFuswIIhI9bclIU8WXjxd7oY=";
                }
                + /palettes/latte.toml
              '';
            description = "Path to the palette file";
          };

          palette.name = mkOption {
            type = types.str;
            example = "catppuccin_latte";
            description = "Name of the palette. Must be one of the palettes in the palette file.";
          };
        };

        themeConfig = { opts, ... }: {
          file."starship.toml".source = tomlFormat.generate "starship-chroma-config" (config.programs.starship.settings // {
            palette = opts.starship.palette.name;
          } // builtins.fromTOML (builtins.readFile (opts.starship.palette.file)));
        };
      };
    })
    (mkIf (cfg.enable && cfg.starship.enable) {
      # IDEA: add functionality to Chroma to generate these symlinks from there?
      xdg.configFile."starship.toml".source = mkForce (config.lib.file.mkOutOfStoreSymlink "${cfg.themeFolder}/active/starship/starship.toml");
    })
  ];
}