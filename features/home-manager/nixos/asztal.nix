{copper, ...}: {
  systemd.user.services.asztal = {
    Unit = {
      Description = "Aylur's configuration for AGS";
      After = ["graphical-session-pre.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      ExecStart = "${copper.inputs.asztal}/bin/asztal";
      Restart = "always";
      BusName = "com.github.Aylur.ags.asztal";
    };
  };
}
