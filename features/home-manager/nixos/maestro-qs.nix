{config, lib, copper, ...}: with lib; let
  cfg = config.copper.feature.nixos.maestro-qs;
in {
  featureOptions = {
    systemd.installTarget = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "hyprland-session.target";
      description = ''
        The systemd target to install the maestro-qs user service to. If null,
        the service will not be installed automatically.
      '';
    };
  };

  config = {
    systemd.user.services.maestro-qs = {
      Unit = {
        Description = "Quickshell keybind popup for maestro";
        After = ["graphical-session-pre.target"];
        PartOf = ["graphical-session.target"];
      };

      Service = {
        ExecStart = "${lib.getExe copper.packages.maestro-qs}";
        Restart = "always";
      };

      Install.WantedBy = mkIf (cfg.systemd.installTarget != null) [cfg.systemd.installTarget];
    };
  };
}
