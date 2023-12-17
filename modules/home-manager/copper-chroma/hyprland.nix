{
  config,
  pkgs,
  lib,
  ...
}:
with lib; {
  options = {
    copper.chroma.hyprland.enable = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether to enable Hyprland theming as part of Chroma.
      '';
    };
  };

  config = {
    copper.chroma.programs.hyprland = {
      activationCommand = {
        name,
        opts,
      }: let
        cursor = config.copper.chroma.themes.${name}.gtk.cursorTheme;
      in
        optionalString (cursor != null) ''
          ${config.wayland.windowManager.hyprland.package}/bin/hyprctl setcursor ${cursor.name} ${toString cursor.size}
        '';
      reloadCommand = ''
        ( ${config.xdg.configFile."hypr/hyprland.conf".onChange} ) >/dev/null 2>&1
      '';
    };

    wayland.windowManager.hyprland = mkIf (config.copper.chroma.enable && config.copper.chroma.hyprland.enable) {
      settings = {
        source = ["${config.copper.chroma.themeFolder}/active/hyprland/theme.conf"];
      };
    };
  };
}
