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

  home.activation.waybarConfigGeneration = lib.hm.dag.entryBetween ["reloadSystemd"] ["linkGeneration"] ''
    ${lib.getExe copper.packages.waybar-confgen-hyprdots}
  '';

  home.packages = [copper.packages.waybar-confgen-hyprdots];

  programs.waybar.style = ''
      @import "${config.xdg.configHome}/waybar/style.mine.css";
  '';

  copper.file.config = lib.genAttrs ["waybar/modules" "waybar/config.ctl"] (n: "config/${n}");
}
