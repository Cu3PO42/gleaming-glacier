{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    systemd.target = "hyprland-session.target";
  };

  home.activation.waybarConfigGeneration = lib.hm.dag.entryBetween ["reloadSystemd"] ["linkGeneration"] ''
    ${lib.getExe pkgs.waybar-confgen-hyprdots}
  '';

  home.packages = [pkgs.waybar-confgen-hyprdots];

  copper.file.config = lib.genAttrs ["waybar/modules" "waybar/config.ctl"] (n: "config/${n}");
}
