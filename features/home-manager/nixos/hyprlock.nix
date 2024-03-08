{config, lib, origin, pkgs, ...}: with lib; let
  cfg = config.copper.feature.nixos.hyprlock;
in {
  featureOptions = {
    suspend.enable = mkEnableOption "Automatic sleep via Hypridle";
  };

  imports = [
    origin.inputs.hypridle.homeManagerModules.default
    origin.inputs.hyprlock.homeManagerModules.default
  ];

  config = {
    programs.hyprlock = {
      enable = true;
      backgrounds = [
        {
          monitor = "";
          path = "${config.xdg.stateHome}/swim/active/wallpaper";
        }
      ];

      general = {
        grace = 5;
      };
    };

    services.hypridle = {
      enable = true;
      beforeSleepCmd = "${pkgs.systemd}/bin/loginctl lock-session";
      lockCmd = lib.getExe config.programs.hyprlock.package;

      listeners = [
        {
          timeout = 300;
          onTimeout = "${pkgs.systemd}/bin/loginctl lock-session";
        }
      ] ++ (optional cfg.suspend.enable {
        timeout = 600;
        onTimeout = "${pkgs.systemd}/bin/systemctl suspend";
      });
    };
  };
}