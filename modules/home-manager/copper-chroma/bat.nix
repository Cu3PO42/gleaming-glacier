{config, lib, pkgs, options, ...}: with lib; let
  cfg = config.copper.chroma;

  # Taken verbatim from upstream bat module:
  toConfigFile = attrs:
    let
      inherit (builtins) isBool attrNames;
      nonBoolFlags = filterAttrs (_: v: !(isBool v)) attrs;
      enabledBoolFlags = filterAttrs (_: v: isBool v && v) attrs;

      keyValuePairs = generators.toKeyValue {
        mkKeyValue = k: v: "--${k}=${lib.escapeShellArg v}";
        listsAsDuplicateKeys = true;
      } nonBoolFlags;
      switches = concatMapStrings (k: ''
        --${k}
      '') (attrNames enabledBoolFlags);
    in keyValuePairs + switches;
in {
  options = {
    copper.chroma.bat = {
      enable = mkEnableOption "Bat theming" // { default = config.programs.bat.enable; };
    };
  };

  config = mkMerge [
    ({
      copper.chroma.programs.bat = {
        themeOptions = {
          theme = mkOption {
            type = options.programs.bat.themes.type.nestedTypes.elemType;
            example = literalExpression ''
              {
                src = pkgs.fetchFromGitHub {
                  owner = "dracula";
                  repo = "sublime"; # Bat uses sublime syntax for its themes
                  rev = "26c57ec282abcaa76e57e055f38432bd827ac34e";
                  sha256 = "019hfl4zbn4vm4154hh3bwk6hm7bdxbr1hdww83nabxwjn99ndhv";
                };
                file = "Dracula.tmTheme";
              }
            '';
            description = "The bat theme to use.";
          };
        };

        templates."config" = { name, opts }: toConfigFile (config.programs.bat.config // { theme = "_chroma_${name}"; });
      };
    })
    (mkIf (cfg.enable && cfg.bat.enable) {
      assertions = [
        {
          assertion = config.programs.bat.enable;
          message = "The bat module is required for Chroma's bat integration.";
        }
        {
          assertion = !(config.home.sessionVariables ? BAT_THEME || config.programs.bat.config ? theme);
          message = "When using Chroma's bat integration, do not configure a theme via other means.";
        }
      ];

      programs.bat = {
        themes = mapAttrs' (name: value: { name = "_chroma_${name}"; value = value.bat.theme; }) cfg.themes;
      };

      xdg.configFile."bat/config".source = mkOverride 1 (config.lib.file.mkOutOfStoreSymlink "${config.copper.chroma.themeFolder}/active/bat/config");
    })
  ];
}