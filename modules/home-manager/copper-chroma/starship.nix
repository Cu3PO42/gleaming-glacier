{config, pkgs, lib, ...}: with lib; let
  cfg = config.copper.chroma;
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
          # Read fetched palettes at build time so evaluating an aarch64
          # configuration does not require an aarch64 builder.
          file."starship.toml".source = let
            settingsFile = (pkgs.formats.toml {}).generate "starship-settings.toml"
              (config.programs.starship.settings // {
                palette = opts.starship.palette.name;
              });
          in pkgs.runCommand "starship.toml" {nativeBuildInputs = [pkgs.remarshal];} ''
            cat ${settingsFile} ${opts.starship.palette.file} > $out
            toml2json $out > /dev/null # fail the build on invalid TOML, e.g. duplicate tables
          '';
        };
      };
    })
    (mkIf (cfg.enable && cfg.starship.enable) {
      # IDEA: add functionality to Chroma to generate these symlinks from there?
      home.file."${config.programs.starship.configPath}".source = mkForce (config.lib.file.mkOutOfStoreSymlink "${cfg.themeDirectory}/active/starship/starship.toml");
    })
  ];
}
