{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.copper.chroma;
in {
  options = {
    copper.chroma.qt.enable = mkOption {
      type = types.bool;
      default = false;
      example = false;
      description = ''
        Whether to enable QT theming via Kvantum as part of Chroma.
      '';
    };
  };

  config = {
    copper.chroma.programs.qt = {
      activationCommand = {
        name,
        opts,
      }: "${pkgs.libsForQt5.qtstyleplugin-kvantum}/bin/kvantummanager --set ${opts.kvantum.name}";

      themeOptions = {
        qtct = {
          package = mkOption {
            type = types.package;
            description = ''
              A package containing Qt5ct colors.
            '';
          };

          name = mkOption {
            type = types.str;
            example = "Catppuccin-Latte";
            description = ''
              The name of the color scheme to apply. Must correspond to the
              name of the folder used in the package definition.
            '';
          };
        };

        kvantum = {
          package = mkOption {
            type = types.package;
            description = ''
              A package containing a Kvantum theme.
            '';
          };

          name = mkOption {
            type = types.str;
            example = "Catppuccin-Latte";
            description = ''
              The name of the folder in the theme package.
            '';
          };
        };
      };

      # TODO: configure font, icon theme, ...
      templates."qt5ct.conf" = {
        name,
        opts,
      }: ''
        [Appearance]
        color_scheme_path=${opts.qtct.package}/share/qt5ct/colors/${opts.qtct.name}.conf
        custom_palette=true
        icon_theme=Tela-circle-dracula
        standard_dialogs=default
        style=kvantum

        [Fonts]
        fixed="CaskaydiaCove Nerd Font Mono,9,-1,5,50,0,0,0,0,0,Regular"
        general="Cantarell,10,-1,5,50,0,0,0,0,0,Regular"

        [Interface]
        activate_item_on_single_click=1
        buttonbox_layout=0
        cursor_flash_time=1000
        dialog_buttons_have_icons=0
        double_click_interval=400
        gui_effects=General, AnimateMenu, AnimateCombo, AnimateTooltip, AnimateToolBox
        keyboard_scheme=2
        menus_have_icons=false
        show_shortcuts_in_context_menus=true
        stylesheets=@Invalid()
        toolbutton_style=4
        underline_shortcut=2
        wheel_scroll_lines=4

        [SettingsWindow]
        geometry=@ByteArray(\x1\xd9\xd0\xcb\0\x3\0\0\0\0\0\0\0\0\0\0\0\0\x4\xf0\0\0\x4\a\0\0\0\0\0\0\0\0\0\0\x2\xde\0\0\x2\xfa\0\0\0\0\x2\0\0\0\n\0\0\0\0\0\0\0\0\0\0\0\x4\xf0\0\0\x4\a)

        [Troubleshooting]
        force_raster_widgets=1
        ignored_applications=@Invalid()
      '';
    };
  };

  imports = [
    (mkIf (cfg.enable && cfg.qt.enable) {
      # TODO: other modules assert that the base module is enabled; handle it in a unified way
      qt = {
        enable = true;
        platformTheme = "qtct";
        style.name = "kvantum";
      };

      xdg.configFile."qt5ct/qt5ct.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.copper.chroma.themeFolder}/active/qt/qt5ct.conf";
      # TODO: is this the right format for qt6ct? does everything work for Qt5/Qt6
      xdg.configFile."qt6ct/qt6ct.conf".source = config.lib.file.mkOutOfStoreSymlink "${config.copper.chroma.themeFolder}/active/qt/qt5ct.conf";

      home.packages = concatLists (mapAttrsToList (name: opts: with opts.qt; [qtct.package kvantum.package]) cfg.themes);
    })
  ];

  # TODO: can we theme Qt apps in Flatpak?
}
