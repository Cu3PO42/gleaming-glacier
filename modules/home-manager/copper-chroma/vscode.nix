{config, pkgs, lib, options, ...}: with lib; let
  cfg = config.copper.chroma;

  optionalPackage = opt:
    optional (opt != null && opt.package != null) opt.package;
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
    
      # TODO: restructure so jaq is only invoked once
      activationCommand = {name, opts}: ''
        ${pkgs.jaq}/bin/jaq -i '."settingsSync.ignoredSettings" |= (. // [] | . += ["workbench.colorTheme", "workbench.iconTheme"] | unique)' "${cfg.vscode.configFolder}/User/settings.json"
      '' + (optionalString (opts.colorTheme != null) ''
        ${cfg.vscode.codeBinary} --install-extension ${opts.colorTheme.extension.id} >/dev/null 2>&1
        ${pkgs.jaq}/bin/jaq -i '."workbench.colorTheme" = "${opts.colorTheme.name}"' "${cfg.vscode.configFolder}/User/settings.json"
      '') + (optionalString (opts.iconTheme != null) ''
        ${cfg.vscode.codeBinary} --install-extension ${opts.iconTheme.extension.id} >/dev/null 2>&1
        ${pkgs.jaq}/bin/jaq -i '."workbench.iconTheme" = "${opts.iconTheme.name}"' "${cfg.vscode.configFolder}/User/settings.json"
      '');
    };
  };

  imports = [
    (mkIf (cfg.enable && cfg.vscode.enable) {
    })
  ];
}