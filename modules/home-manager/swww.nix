{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.programs.swww;
in {
  options = {
    programs.swww = {
      enable = mkEnableOption "swww";
      package = mkPackageOption pkgs "swww" {};
      systemd.enable = mkEnableOption "swww systemd user service";
      systemd.installTarget = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "hyprland-session.target";
        description = ''
          The systemd target to install the user service to. If null, the
          service will not be installed.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [cfg.package];
    systemd.user.services.swww = mkIf cfg.systemd.enable {
      Unit = {
        Description = "swww wallpaper daemon";
        After = ["graphical-session-pre.target"];
        PartOf = ["graphical-session.target"];
      };

      Service = {
        Environment = "PATH=${cfg.package}/bin";
        ExecStart = "${cfg.package}/bin/swww-daemon";
      };

      Install.WantedBy = mkIf (cfg.systemd.installTarget != null) [cfg.systemd.installTarget];
    };
  };
}
