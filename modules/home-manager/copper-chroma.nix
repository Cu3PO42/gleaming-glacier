{
  lib,
  config,
  pkgs,
  options,
  modulesPath,
  copper,
  ...
}:
with lib; let
  cfg = config.copper.chroma;

  symlinkJoinInFolder = {
    name,
    drvs,
  }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit name;
      dontUnpack = true;
      dontBuild = true;
      installPhase = ''
        mkdir $out
        ${builtins.concatStringsSep "\n" (lib.mapAttrsToList (name: drv: "ln -s ${drv} $out/${name}") drvs)}
      '';
    };

  fileType = types.submodule ({ name, config, ... }: {
    options = {
      source = mkOption {
        type = with types; nullOr path;
        default = null;
        example = literalExpression "./theme.conf";
        description = ''
          The path to the file that will be linked.
        '';
      };

      text = mkOption {
        type = with types; nullOr str;
        default = null;
        description = ''
          The text that will be written to the file.
        '';
      };

      required = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Whether this file is required for the theme to be considered valid.
        '';
      };
    };

    config = {
      source = mkIf (config.text != null) (mkDefault (pkgs.writeTextFile {
        inherit (config) text;
        name = hm.strings.storeFileName name;
      }));
    };
  });

  themeForProgramType = programOpts:
    types.submodule ({config, ...}: {
      options =
        {
          themeName = mkOption {
            type = types.str;
            visible = false;
            # FIXME: setting this to readOnly shouldn't be a problem, but it is
            #readOnly = true;
            example = "Catppuccin-Latte";
            description = ''
              The name of the theme as part of which this set of options was
              defined.
            '';
          };

          file = mkOption {
            type = types.attrsOf fileType;
            default = {};
            example = literalExpression ''{ "theme.conf".source = ./themes/Catppuccin-Latte/kitty/theme.conf; }'';
            description = ''
              Which files need to be linked for the config of the particular program.
              It is generally expected that the module setting up the config for this
              program makes sure that these files are included.
            '';
          };

          extraActivationCommands = mkOption {
            type = types.str;
            default = "";
            description = ''
              Extra code that will be run when this particular theme is activtated.
              This should probably be seldomly needed and instead handled in the
              generic activation commands.
            '';
          };
        }
        // programOpts.themeOptions;

      config = programOpts.themeConfig {inherit config; opts = cfg.themes.${config.themeName}; };
    });

  themeType = types.submodule ({
    name,
    config,
    ...
  }: {
    freeformType = with types; attrsOf anything;

    options =
      {
        name = mkOption {
          type = types.str;
          example = "Catppuccin-Latte";
          description = ''
            The name for this theme. Defaults to the name of the theme attribute.
          '';
        };

        fallbacks = mkOption {
          type = types.listOf types.str;
          default = [];
          example = ["Catppuccin-Latte" "Catppuccin-Frappe"];
          description = ''
            If theming for a given program is not defined in the current theme,
            this defines the next themes that will be checked. The initialTheme
            is always used as the last fallback.
          '';
        };
      }
      // mapAttrs (programName: programOpts:
        mkOption {
          type = types.nullOr (themeForProgramType programOpts);
          default = null;
          description = ''Theming for ${programName}'';
        })
      cfg.programs;

    config =
      {
        name = mkDefault name;
        # TODO: this may prevent us from simply leaving off the options for one program
      }
      // mapAttrs (programName: _: {themeName = config.name;}) cfg.programs;
  });

  programType = types.submodule {
    options = {
      reloadCommand = mkOption {
        type = types.str;
        default = "";
        example = "killall -SIGUSR1 kitty";
        description = ''
          The command to run to reload the config for the given application.
        '';
      };

      activationCommand = mkOption {
        type = types.functionTo types.str;
        example = literalExpression ''
          { name, opts }: gsettings
        '';
        default = {...}: "";
        description = ''
          Commands that need to be run to set up the settings for the
          application. For example, by editing dbus settings. These commands
          are executed when the theme is first activated and every subsequent
          restart.
        '';
      };

      themeOptions = mkOption {
        # FIXME: what is the type for this;, something like subtreeOF types.optionType; maybe apply in themeConfig, too
        type = types.anything;
        default = {};
        description = ''
          The options that need to be defined on a theme for theming of the
          particular application.
        '';
      };

      themeConfig = mkOption {
        type = with types; functionTo anything;
        default = {...}: {};
        example = literalExpression ''{ config, ... }: { file."wallpapers".source = config.wallpaperDirectory; }'';
        description = ''
          Default settings that are to be constructed for a theme for this
          program.
        '';
      };
      
      specializedConfig = mkOption {
        type = with types; nullOr (functionTo anything);
        default = null;
        description = ''
          A function that is is called with the theme options that returns
          options to be used is a specialized, theme-specific config.
        '';
      };
    };
  };

  buildThemeApplication = theme: programName: programOpts:
    pkgs.stdenvNoCC.mkDerivation {
      name = "theme-${programName}-${theme.themeName}";
      dontUnpack = true;
      dontBuild = true;
      installPhase = ''
        mkdir $out

        lnmkdir ()
        {
          mkdir -p $(dirname "$2")
          ln -s "$1" "$2"
        }

        # First, link all the specified files
        ${concatStringsSep "\n" (mapAttrsToList (name: path: ''lnmkdir "${path.source}" "$out/${name}"'') (filterAttrs (n: v: v.source != null) theme.file))}

        # Write reload and activation scripts.
        cp ${pkgs.writeShellScript "reload" programOpts.reloadCommand} "$out/reload"
        cp ${pkgs.writeShellScript "activate" (programOpts.activationCommand {
            name = theme.themeName;
            opts = theme;
          }
          + "\n"
          + theme.extraActivationCommands)} "$out/activate"
      '';
    };

  resolveFallbacks = name: opts: let
    selectionOrder = [name] ++ opts.fallbacks ++ [cfg.initialTheme];
    selectFromTheme = programName: themeName: cfg.themes.${themeName}.${programName};
    getProgramOpts = programName: _: findFirst (o: o != null) null (map (selectFromTheme programName) selectionOrder);
  in
    {
      inherit (opts) name fallbacks;
    }
    // mapAttrs getProgramOpts cfg.programs;

  buildTheme = _: opts: let
    programThemes = mapAttrs (programName: buildThemeApplication opts.${programName} programName) (filterAttrs (name: _: cfg.${name}.enable) cfg.programs);
    joinScripts = scriptName: extraText: ''
      cp ${pkgs.writeShellScript scriptName (concatStringsSep "\n" (mapAttrsToList (_: value: "${value}/${scriptName}") programThemes) + "\n" + extraText)} ${scriptName}
    '';
  in
    pkgs.stdenvNoCC.mkDerivation {
      name = "theme-${opts.name}";

      dontUnpack = true;

      buildPhase = ''
        cp ${pkgs.writeText "info.json" (builtins.toJSON {inherit (opts) name;})} ./info.json

        ${joinScripts "activate" (concatMapStringsSep "\n" (fn: "( ${fn opts} )") cfg.extraActivationCommands)}
        ${joinScripts "reload" ""}
      '';

      installPhase = ''
        mkdir $out

        ${concatStringsSep "\n" (mapAttrsToList (name: value: ''ln -s ${value} "$out/${name}"'') programThemes)}

        mv * $out/
      '';
    };
in {
  options = {
    copper.chroma = {
      enable = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Whether to enable the theming module.
        '';
      };

      themeDirectory = mkOption {
        type = types.str;
        readOnly = true;
        default = "${config.xdg.configHome}/chroma";
        description = ''
          The location at which the theme data is constructed.
        '';
      };

      themes = mkOption {
        type = types.attrsOf themeType;
        description = ''
          Defines all the themes that can be switched between.
        '';
      };

      finalThemes = mkOption {
        type = types.attrsOf themeType;
        readOnly = true;
        default = mapAttrs resolveFallbacks cfg.themes;
        description = ''
          The same themes as in "`copper.chroma.themes`" with fallback
          resolution applied.
        '';
      };

      themePackages = mkOption {
        type = types.attrsOf types.package;
        readOnly = true;
        default = mapAttrs buildTheme cfg.finalThemes;
        description = ''
          The compiled theme packages for all given themes.
        '';
      };

      themeSpecializations = mkOption {
        type = with types; attrsOf (nullOr (submoduleWith {
          description = "Chroma theme specialization";
          specialArgs = {
            inherit lib modulesPath;
          };
          modules = [({
            imports = import modulesPath + "/modules.nix" {
              inherit pkgs lib;
              # Use the same nixpkgs as the main config.
              useNixpkgsModule = false;
            };

            config = {
              # Pretend we will install packages, but we won't actually do it.
              submoduleSupport.enable = true;
              submoduleSupport.externalPackageInstall = true;

              home.userhame = config.home.username;
              home.homeDirectory = config.home.homeDirectory;

              nix.package = config.nix.package;
            };
          })];
        }));
        readOnly = true;
        default = let
          specializationRequired = any (program: program.specializedConfig != null) (attrValues cfg.programs);
        in mapAttrs (name: theme: if specializationRequired then {
          imports = filter (v: v != null) (mapAttrsToList (_: program: program.specializedConfig theme) cfg.programs);
        } else null) cfg.themes;
        description = ''
          A specialized config that is built, but never to be activated. It
          only exists to copy configuration files or similar to our main
          config.
        '';
      };

      initialTheme = mkOption {
        type = types.str;
        example = "Cattpuccin-Frappe";
        description = ''
          The theme that will be originally selected when activating a theming
          configuration for the first time. This theme is also used as a
          fallback when a particular attribute is missing from the current
          theme.
        '';
      };

      programs = mkOption {
        type = types.attrsOf programType;
        default = {};
        description = ''
          Integrates programs with the theming system.
        '';
      };

      extraActivationCommands = mkOption {
        type = with types; coercedTo (functionTo str) (e: [e]) (listOf (functionTo str));
        default = [];
        example = ''theme: "echo ''${theme.name} activated"'';
        description = ''
          Extra commands that will be run when a theme is activated.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions =
      [
        {
          assertion = cfg.themes ? "${cfg.initialTheme}";
          message = "The theme configured as initial must be provided. Given: ${cfg.initialTheme}, available: ${concatStringsSep " " (builtins.attrNames cfg.themes)}";
        }
      ]
      ++ lib.flatten (lib.mapAttrsToList (name: theme:
        builtins.map (fallback: {
          assertion = cfg.themes ? fallback;
          message = "The theme ${fallback} used as a fallback for ${name} must be defined.";
        })
        theme.fallbacks
        ++ flatten (map (prog: mapAttrsToList (fileName: val: {
          assertion = !val.required || val.source != null;
          message = "The file ${fileName} needs to be defined for ${prog} in theme ${name}.";
        }) theme.${prog}.file) (filter (prog: cfg.${prog}.enable) (attrNames cfg.programs))))
      cfg.themes);

    home.file."${cfg.themeDirectory}/themes".source = symlinkJoinInFolder {
      name = "chroma-themes";
      drvs = cfg.themePackages;
    };
    home.file."${cfg.themeDirectory}/themes.json".text = builtins.toJSON (builtins.attrNames cfg.themes);
    home.activation.activateChroma = lib.hm.dag.entryAfter ["linkGeneration" "installPackages"] ''
      # If no theme is currently active, activate the default theme.
      mkdir -p ${cfg.themeDirectory}
      if ! [ -d "${cfg.themeDirectory}/active" ]; then
        ln -s "${cfg.themeDirectory}/themes/${cfg.initialTheme}" "${cfg.themeDirectory}/active"
      fi

      ${cfg.themeDirectory}/active/reload
      ${cfg.themeDirectory}/active/activate
    '';

    home.packages = [copper.packages.chromactl];
  };
}
