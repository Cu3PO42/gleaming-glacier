{config, lib, pkgs, ...}: {
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      clock = true;
      indicator = true;
      grace = 5;
      image = lib.mkIf config.copper.swim.enable "${config.xdg.stateHome}/swim/active/wallpaper";
      daemonize = true;
    };
  };

  services.swayidle = {
    enable = true;
    systemdTarget = "hyprland-session.target";
    timeouts = [
      { timeout = 600; command = "${pkgs.systemd}/bin/loginctl lock-session"; }
      {
        timeout = 1200;
        command = "${config.wayland.windowManager.hyprland.finalPackage}/bin/hyprctl dispatch dpms off";
        resumeCommand = "${config.wayland.windowManager.hyprland.finalPackage}/bin/hyprctl dispatch dpms on";
      }
      { timeout = 1800; command = "${pkgs.systemd}/bin/systemctl suspend"; }
    ];
    events = [
      { event = "before-sleep"; command = "${pkgs.systemd}/bin/loginctl lock-session";}
      { event = "lock"; command = "${lib.getExe config.programs.swaylock.package}"; }
    ];
  };
}
