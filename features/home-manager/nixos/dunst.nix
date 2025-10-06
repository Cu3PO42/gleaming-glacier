{
  config,
  pkgs,
  ...
}: {
  services.dunst = {
    enable = true;
    settings = {
      global = {
        dmenu = "${pkgs.rofi}/bin/rofi -dmenu -p dunst";
        browser = "${pkgs.xdg-utils}/bin/xdg-open";
      };

      urgency_low.icon = "${config.xdg.configHome}/dunst/icons/hyprdots.svg";
      urgency_normal.icon = "${config.xdg.configHome}/dunst/icons/hyprdots.svg";
      urgency_critical.icon = "${config.xdg.configHome}/dunst/icons/critical.svg";
    };
  };
  systemd.user.services.dunst.Install.WantedBy = ["hyprland-session.target"];

  copper.file.config."dunst/dunstrc.d/00-hyprdots" = "config/dunst/dunstrc.d/00-hyprdots";
  # TODO: some icons, in particular volume icons are needed by the volumecontrol script and should maybe be colocated with that
  copper.file.config."dunst/icons" = "config/dunst/icons";

  copper.desktopEnvironment.notificationDaemon = "dunst";
}
