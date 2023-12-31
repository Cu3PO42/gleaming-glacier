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
      default = config.wayland.windowManager.hyprland.enable;
      example = false;
      description = ''
        Whether to enable Hyprland theming as part of Chroma.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = !(config.copper.chroma.enable && config.copper.chroma.hyprland.enable) || config.wayland.windowManager.hyprland.enable;
        message = "Chroma's Hyprland integration only works when the Hyprland module is enabled";
      }
      {
        assertion = !(config.copper.chroma.enable && config.copper.chroma.hyprland.enable) || config.copper.chroma.desktop.enable;
        message = "Chroma's desktop module is required for the Hyprland module.";
      }
    ];

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
