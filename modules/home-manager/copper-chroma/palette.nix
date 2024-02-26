{config, pkgs, lib, copper, origin, ...}: with lib; let
  cfg = config.copper.chroma;

  inherit (origin.self.lib.types) colorType;

  mkColorOption = name: mkOption {
    type = colorType;
    example = "ff0000";
    description = "The color used for ${name}.";
  };

in {
  options = {
    copper.chroma.palette.enable = mkOption {
      type = types.bool;
      default = true;
      readOnly = true;
      description = ''
        Enables the Chroma palette module.

        The palette module allows for dynamically generating theme files for
        various applications from a palette. It does no theming on its own
        and can therefore not be disabled.
      '';
    };
  };

  config = mkMerge [
    {
      copper.chroma.programs.palette = {
        themeOptions = {
          generateDynamic = mkOption {
            type = with types; functionTo path;
            readOnly = true;
            description = ''
              Generates a theme file based on the given template and palette.
            '';
          };

          semantic = {
            text = mkColorOption "text";
            text1 = mkColorOption "Subtext";
            text2 = mkColorOption "Sub-Subtext";
            overlay = mkColorOption "overlay";
            surface = mkColorOption "surface";
            background = mkColorOption "background";
            accent1 = mkColorOption "primary accent";
            accent2 = mkColorOption "secondary accent";
            accent3 = mkColorOption "tertiary accent";
          };

          colors = mkOption {
            type = with types; attrsOf colorType;
            default = {};
            description = ''
              Shades of common colors that are used for semantic highlighting.
              For example, a shade of red might be used for error messages.
            '';
          };

          # Arbitrary accent colors?
          accents = mkOption {
            type = with types; attrsOf colorType;
            default = {};
            description = ''
              Accent colors defined by the palette. These are not directly
              used, but rather referred by other settings.
            '';
          };

          all = mkOption {
            type = with types; attrsOf colorType;
            default = {};
            description = ''
              All colors defined by the palette. These are not directly
              used, but rather referred by other settings.
            '';
          };

          # TODO: All of the terminal colors?? (0 through 15)
        };

        themeConfig = {config, opts, ...}: {
          generateDynamic = { template, paletteOverrides }: with lib; let
            templateName = baseNameOf (toString template);
            name = substring 0 (stringLength templateName - 4) templateName;
            palette = config.file."palette.json".source;
            overrides = concatStringsSep " " (mapAttrsToList (k: v: "--override ${k}=${v}") paletteOverrides);
          in pkgs.runCommand name {} ''
            echo "${template}"
            echo "${palette}"
            echo "${overrides}"
            ${lib.getExe copper.packages.dynachrome} "${template}" "${palette}" ${overrides} > $out
          '';

          file."palette.json".text = builtins.toJSON { inherit (config) semantic colors accents; };
        };
      };
    }
  ];
}