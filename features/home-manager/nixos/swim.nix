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
  # TODO: this doesn't belong here
  copper.chroma.themes.Catppuccin-Latte.swim.wallpaperDirectory = "${config.home.homeDirectory}/wallpapers/latte";
  copper.chroma.themes.Catppuccin-Mocha.swim.wallpaperDirectory = "${config.home.homeDirectory}/wallpapers/mocha";
}
