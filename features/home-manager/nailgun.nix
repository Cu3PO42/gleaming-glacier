{config, lib, copper, ...}: with lib; {
  featureOptions = {
    activeWallpaperDir = mkOption {
      type = types.str;
      readOnly = true;
      default = "${config.xdg.stateHome}/nailgun/active-wallpaper";
    };
  };

  config = {
    home.packages = [copper.packages.rofi-launchers-hyprdots copper.packages.nailgun];

    copper.chroma.extraActivationCommands = theme: ''
      ${lib.getExe copper.packages.nailgun} thumbnails-for-theme "${config.copper.chroma.themeDirectory}/active/swim/wallpapers" >/dev/null &
    '';

    copper.swim.wallpaperActivationCommands = ''
      ${lib.getExe copper.packages.nailgun} activate-wallpaper "$WALLPAPER" >/dev/null &
    '';
  };
}