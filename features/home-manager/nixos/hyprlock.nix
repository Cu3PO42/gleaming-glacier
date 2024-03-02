{config, lib, origin, pkgs, ...}: {
  imports = [
    origin.inputs.hypridle.homeManagerModules.default
    origin.inputs.hyprlock.homeManagerModules.default
  ];

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
      {
        timeout = 600;
      }
    ];
  };
}