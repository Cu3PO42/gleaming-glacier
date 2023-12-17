{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    terminal = "${pkgs.kitty}/bin/kitty";
  };

  # We disable writing of the config file as determined by Home-Manager, because we want to manage it ourselves.
  home.file."${config.programs.rofi.configPath}".enable = false;

  copper.file.config = lib.genAttrs ["rofi/clipboard.rasi" "rofi/quickapps.rasi" "rofi/themeselect.rasi" "rofi/styles"] (i: "config/${i}");
  home.activation.linkRofiDefaultStyle = lib.hm.dag.entryAfter ["write-boundary"] ''
    if ! [ -e "${config.xdg.configHome}/rofi/config.rasi" ]; then
      ln -s "${config.xdg.configHome}/rofi/styles/style_1.rasi" "${config.xdg.configHome}/rofi/config.rasi"
    fi
  '';

  home.packages = [pkgs.rofi-launchers-hyprdots pkgs.nailgun];
  # TODO: icon theme, maybe font and such should be configured dynamically as well.

  copper.chroma.extraActivationCommands = theme: ''
    ${lib.getExe pkgs.nailgun} thumbnails-for-theme "${config.copper.chroma.themeFolder}/active/swim/wallpapers" >/dev/null &
  '';

  copper.swim.wallpaperActivationCommands = ''
    ${lib.getExe pkgs.nailgun} activate-wallpaper "$WALLPAPER" >/dev/null &
  '';
}
