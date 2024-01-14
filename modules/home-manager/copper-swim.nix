{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.copper.swim;

  wallpaperDir =
    if cfg.chromaIntegration.enable
    then "${config.copper.chroma.themeDirectory}/active/swim/wallpapers"
    else cfg.wallpaperDirectory;

  mkSwimActivation = {name}: ''
    SWIM_STATE_DIR="''${XDG_STATE_HOME:-$HOME/.local/state}/swim"
    mkdir -p "$SWIM_STATE_DIR/${name}"
    ln -sfn "$SWIM_STATE_DIR/${name}" "$SWIM_STATE_DIR/active"
    if ! [ -e "$SWIM_STATE_DIR/active/wallpaper" ]; then
      ln -sfn "$(find "${wallpaperDir}/" -type f | head -1)" "$SWIM_STATE_DIR/active/wallpaper"
    fi
    ${pkgs.swimctl}/bin/swimctl activate
  '';
in {
  options = {
    copper.swim = {
      enable = mkEnableOption "swim wallpaper manager";

      wallpaperDirectory = mkOption {
        type = with types; nullOr (oneOf [str path]);
        example = literalExpression ''''${config.home.homeDirectory}/wallpapers'';
        description = ''
          The location where wallpapers are stored. If specified as a string,
          it is interpreted as a path on your filesystem. If specified as a
          path, the wallpapers will be stored in and loaded from the Nix store.
        '';
      };

      configurationDirectory = mkOption {
        type = types.str;
        default = ''${config.xdg.configHome}/swim'';
        example = "$HOME/.swim";
        description = ''
          The location where swim stores its configuration. This includes the
          wallpaper folders and activation scripts. Note that any non-standard
          location must be manually passed to swimctl by setting the
          SWIM_CONFIG_DIR environment variable.
        '';
      };

      chromaIntegration = {
        enable = mkOption {
          type = types.bool;
          default = true;
          example = false;
          description = ''
            Whether to enable the chroma integration. This will automatically
            change the wallpaper based on the current theme. It also makes it
            possible to specify theme-specific wallpapers as part of the theme.
          '';
        };
      };

      systemd = {
        enable = mkEnableOption "swim systemd service";

        installTarget = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "hyprland-session.target";
          description = ''
            The target to install the systemd service to.
          '';
        };
      };

      wallpaperActivationCommands = mkOption {
        type = types.lines;
        default = "";
        example = ''dunstify t1 -i "$WALLPAPER"'';
        # TODO: it might be nice to have the ability to pass a tool that receives the wallpaper path as an argument
        # this might be an opportunity to learn about coercible types
        description = ''
          Commands to run when the wallpaper changes. The wallpaper path will
          be available in the WALLPAPER environment variable.
        '';
      };

      extraSwwwArgs = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [''--transition-pos'' ''"$( hyprctl cursorpos )"''];
        description = ''
          Extra arguments to pass to swww. This can be used to customize
          transitions.
        '';
      };
    };

    copper.chroma.swim.enable = mkEnableOption "Chroma integration for Swim" // { readonly = true; default = config.copper.swim.chromaIntegration.enable; };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.wallpaperDirectory != null || cfg.chromaIntegration.enable;
        message = "You must specify a wallpaper directory or enable chroma integration.";
      }
    ];

    copper.chroma.programs.swim = mkIf cfg.chromaIntegration.enable {
      themeOptions = {
        wallpaperDirectory = mkOption {
          type = with types; nullOr (oneOf [str path]);
          example = literalExpression ''./wallpapers'';
          description = ''
            The location where wallpapers are stored. If specified as a string,
            it is interpreted as a path on your filesystem. If specified as a
            path, the wallpapers will be stored in and loaded from the Nix store.
          '';
        };
      };

      themeConfig = {config, ...}: {
        file."wallpapers".source = config.wallpaperDirectory;
      };

      activationCommand = {
        name,
        opts,
      }:
        mkSwimActivation {inherit name;};
    };

    home.file."${cfg.configurationDirectory}/config.json".text = builtins.toJSON {
      inherit (cfg) extraSwwwArgs;
      wallpaperDirectory =
        if cfg.chromaIntegration.enable
        then "${config.copper.chroma.themeDirectory}/active/swim/wallpapers"
        else cfg.wallpaperDirectory;
    };

    home.file."${cfg.configurationDirectory}/activate" = {
      text = ''
        #!${pkgs.bash}/bin/bash
        ${cfg.wallpaperActivationCommands}
      '';
      executable = true;
    };

    home.packages = [pkgs.swimctl];

    home.activation.swim = mkIf (!cfg.chromaIntegration.enable) (lib.hm.dag.entryAfter ["writeBoundary"] (mkSwimActivation {name = "no-chroma";}));

    systemd.user.services.swim-activation = mkIf cfg.systemd.enable {
      Unit = {
        Description = "swim wallpaper manager activation";
        Requires = ["swww.service"];
        After = ["swww.service"];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.swimctl}/bin/swimctl activate";
      };

      Install.WantedBy = mkIf (cfg.systemd.installTarget != null) [cfg.systemd.installTarget];
    };
  };

  # TODO: random cycling? how is that configured? is there some dynamicity? do we configure systemd timers? do we write a daemon?
}
