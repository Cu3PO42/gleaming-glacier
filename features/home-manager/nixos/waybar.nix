{
  config,
  lib,
  pkgs,
  copper,
  ...
}: {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    systemd.target = "hyprland-session.target";
  };

  programs.waybar.style = ''
      @import "${config.xdg.configHome}/waybar/style.mine.css";
  '';
}
