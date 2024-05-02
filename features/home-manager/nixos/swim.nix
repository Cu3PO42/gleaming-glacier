{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.swww = {
    enable = true;
    systemd = {
      enable = true;
      installTarget = "hyprland-session.target";
    };
  };

  copper.swim = {
    enable = true;
    chromaIntegration = {
      enable = true;
    };
    wallpaperDirectory = "${config.home.homeDirectory}/wallpapers";
    extraSwwwArgs = lib.mkIf config.copper.feature.nixos.hyprland.enable [''--transition-pos'' ''"$( hyprctl cursorpos )"''];
  };
}
