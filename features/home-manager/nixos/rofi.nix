{
  config,
  pkgs,
  lib,
  copper,
  ...
}: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
    terminal = "${pkgs.kitty}/bin/kitty";
    font = "JetBrainsMono Nerd Font 10";
    # FIXME: by default location, xoffset, yoffset are set; we probably don't want these set here
    imports = ["${config.xdg.configHome}/rofi/config.style.rasi"];
  };

  copper.file.config = lib.genAttrs ["rofi/clipboard.rasi" "rofi/quickapps.rasi" "rofi/themeselect.rasi" "rofi/styles"] (i: "config/${i}");
  home.activation.linkRofiDefaultStyle = lib.hm.dag.entryAfter ["write-boundary"] ''
    if ! [ -e "${config.xdg.configHome}/rofi/config.style.rasi" ]; then
      ln -s "${config.xdg.configHome}/rofi/styles/style_1.rasi" "${config.xdg.configHome}/rofi/config.style.rasi"
    fi
  '';

  home.packages = [copper.packages.rofi-launchers-hyprdots copper.packages.nailgun];
  # TODO: icon theme, maybe font and such should be configured dynamically as well.

  copper.chroma.extraActivationCommands = theme: ''
    ${lib.getExe copper.packages.nailgun} thumbnails-for-theme "${config.copper.chroma.themeDirectory}/active/swim/wallpapers" >/dev/null &
  '';

  copper.swim.wallpaperActivationCommands = ''
    ${lib.getExe copper.packages.nailgun} activate-wallpaper "$WALLPAPER" >/dev/null &
  '';
}
