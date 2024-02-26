{config, lib, copper, ...}: with lib; let
  cfg = config.programs.maestro;
in {
  options = {
    programs.maestro = {
      enable = mkEnableOption "maestro";

      package = mkOption {
        type = types.package;
        default = copper.packages.maestro;
        description = ''
          The maestro package to use.
        '';
      };

      systemdTarget = mkOption {
        type = types.nullOr types.str;
        default = "hyprland-session.target";
        example = "sway-session.target";
        description = ''
          The systemd target to install the maestro service into.
        '';
      };


      cancelCommand = mkOption {
        type = types.str;
        default = "";
        example = "hyprctl dispatch submap reset";
        description = ''
          Command to run to exit a keymap. Will be executed in sh.
        '';
      };

      keymapTimeout = mkOption {
        type = types.int;
        default = 30;
        description = ''
          Time in seconds to wait before returning to the root keymap.
        '';
      };

      helpCommand = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "mac-show-keymap --keymap $KEYMAP";
        description = ''
          Command to run to showthe keymap help. Will be run in sh.
          The process should stay alive while the help is being displayed and
          hide the help when killed. The currently active keymap is available
          in the `KEYMAP` environment variable.

          If set to null, the current implementation does not support showing
          a help.
        '';
      };

      helpTimeout = mkOption {
        type = types.int;
        default = 5;
        description = ''
          Time in seconds to wait after a keymap has been activated before
          showing the help, if no other bind has been used.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."maestro/config.json".text = builtins.toJSON {
      inherit (cfg) cancelCommand keymapTimeout helpCommand helpTimeout;
    };

    home.packages = [cfg.package];

    systemd.user.services."maestro" = {
      Unit = {
        Description = "Maestro modal keymap helper";
        After = ["graphical-session-pre.target"];
        PartOf = ["graphical-session.target"];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/maestrod";
        Restart = "always";
      };
    
      Install.WantedBy = mkIf (cfg.systemdTarget != null) [cfg.systemdTarget];
    };

    launchd.agents."maestro" = {
      enable = true;
      config = {
        Program = "${cfg.package}/bin/maestrod";
        RunAtLoad = true;
        KeepAlive = true;
      };
    };
  };
}