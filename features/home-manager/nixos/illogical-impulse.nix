{config, lib, copper, ...}: with lib; {
  featureOptions = {};

  config = {
    systemd.user.services.illogical-impulse = {
      Unit = {
        Description = "Aylur's Gtk Shell - Illogical Impulse by end-4";
        Documentation = "https://aylur.github.io/ags-docs/";
        After = ["graphical-session-pre.target"];
        PartOf = ["graphical-session.target"];
      };

      Service = {
        ExecStart = getExe copper.packages.illogical-impulse;
        Restart = "always";
        BusName = "com.github.Aylur.ags.illogicalimpulse";
      };
    };

    copper.swim.wallpaperActivationCommands = ''
      ${copper.packages.illogical-impulse.config}/scripts/color_generation/colorgen.sh "$WALLPAPER" --apply --smart
    '';

    copper.desktopEnvironment = {
      notificationDaemon = "illogical-impulse";
      systemTray = "illogical-impulse";
    };
  };
}