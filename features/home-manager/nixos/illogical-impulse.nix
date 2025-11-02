{config, lib, copper, ...}: with lib; {
  featureOptions = {};

  config = {
    systemd.user.services.illogical-impulse = {
      Unit = {
        Description = "Illogical Impulse by end-4";
        Documentation = "https://ii.clsty.link/en/";
        After = ["graphical-session-pre.target"];
        PartOf = ["graphical-session.target"];
      };

      Service = {
        ExecStart = getExe copper.packages.illogical-impulse-qs;
        Restart = "always";
      };
    };

    copper.swim.wallpaperActivationCommands = ''
      ${copper.packages.illogical-impulse-qs}/share/ii/scripts/colors/switchwall.sh "$(realpath "$WALLPAPER")"
    '';

    copper.desktopEnvironment = {
      notificationDaemon = "illogical-impulse";
      systemTray = "illogical-impulse";
      polkitAgent = "illogical-impulse";
    };
  };
}