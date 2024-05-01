{config, pkgs, lib, ...}: with lib; let
  cfg = config.copper.chroma;
in {
  options = {
    copper.chroma.vscode = {
      enable = mkEnableOption "VSCode settings for Chromma";

      codeBinary = mkOption {
        type = types.path;
        default = "${pkgs.vscode}/bin/code";
        description = ''
          The VSCode command line binary that is used to install extensions.
        '';
      };

      configFolder = mkOption {
        type = types.path;
        default = "${config.xdg.configHome}/Code";
        description = ''
          The location in which your VS Code stores your configuration.
        '';
      };
    };
  };

  config = {
    copper.chroma.programs.vscode = {
      themeOptions = rec {
        colorTheme = mkOption {
          type = types.nullOr (types.submodule ({
            options = {
              extension.id = mkOption {
                type = types.str;
                example = "";
                description = ''
                  The ID of the extension on your marketplace that contains the
                  theme we want to set.
                '';
              };

              name = mkOption {
                type = types.str;
                example = "Catppuccin Latte";
                description = ''
                  The name of the theme we want to set.
                '';
              };
            };
          }));
          default = null;
        };

        iconTheme = colorTheme;
      };
    
      activationCommand = {name, opts}: let
        desiredSettings = (if opts.colorTheme != null then {
          "workbench.colorTheme" = opts.colorTheme.name;
        } else {}) // (if opts.iconTheme != null then {
          "workbench.iconTheme" = opts.iconTheme.name;
        } else {});
        keys = builtins.attrNames desiredSettings;
      in (optionalString (opts.colorTheme != null) ''
        ${cfg.vscode.codeBinary} --install-extension ${opts.colorTheme.extension.id} >/dev/null 2>&1
      '') + (optionalString (opts.iconTheme != null) ''
        ${cfg.vscode.codeBinary} --install-extension ${opts.iconTheme.extension.id} >/dev/null 2>&1
      '') + ''
        # First make sure the settings file exists.
        mkdir -p "${cfg.vscode.configFolder}/User"
        if [ ! -f "${cfg.vscode.configFolder}/User/settings.json" ]; then
          echo '{}' > "${cfg.vscode.configFolder}/User/settings.json"
        fi

        # Set all settings and ignore them for sync.
        ${pkgs.jaq}/bin/jaq -i '. * ${builtins.toJSON desiredSettings} | (."settingsSync.ignoredSettings" |= (. // [] | . += ${builtins.toJSON keys} | unique))' "${cfg.vscode.configFolder}/User/settings.json"
      '';
    };
  };
}