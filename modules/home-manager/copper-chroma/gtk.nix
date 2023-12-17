# This file contains some bits of code from the HM GTK module
# (at home-manager/modules/misc/gtk.nix), available originally under the terms
# of the MIT license. It is relicensed here as GPLv3 (or later).
{
  config,
  options,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.copper.chroma;

  isIntConstant = v: v ? constant;
  mkIntConstant = v: {constant = v;};

  toGtk3Ini = generators.toINI {
    mkKeyValue = key: value: let
      value' =
        if isBool value
        then boolToString value
        else if isIntConstant value
        then value.constant
        else toString value;
    in "${escape ["="] key}=${value'}";
  };

  toDconfIni = generators.toINI {
    mkKeyValue = key: value: let
      value' =
        if isBool value
        then boolToString value
        else if isString value
        then "'${value}'"
        else toString value;
    in "${escape ["="] key}=${value'}";
  };

  formatGtk2Option = n: v: let
    v' =
      if isBool v
      then boolToString v
      else if isIntConstant v
      then v.constant
      else if isString v
      then ''"${v}"''
      else toString v;
  in "${escape ["="] n} = ${v'}";

  # TODO: make these configurable elsewhere
  gtkBaseSettings = {
    gtk-toolbar-style = mkIntConstant "GTK_TOOLBAR_ICONS";
    gtk-toolbar-icon-size = mkIntConstant "GTK_ICON_SIZE_LARGE_TOOLBAR";
    gtk-button-images = 0;
    gtk-menu-images = 0;
    gtk-enable-event-sounds = 1;
    gtk-enable-input-feedback-sounds = 0;
    gtk-xft-antialias = 1;
    gtk-xft-hinting = 1;
    gtk-xft-hintstyle = "hintfull";
    gtk-xft-rgba = "rgb";
  };

  dconfBaseSettings = {
    font-antialiasing = "rgba";
    font-hinting = "full";
  };

  toFontString = font: let
    fontSize = optionalString (font.size != null) " ${toString font.size}";
  in
    "${font.name}" + fontSize;

  gtkIniForTheme = theme:
    gtkBaseSettings
    // optionalAttrs (theme.font != null) {
      gtk-font-name = toFontString theme.font;
    }
    // optionalAttrs (theme.theme != null) {gtk-theme-name = theme.theme.name;}
    // optionalAttrs (theme.iconTheme != null) {
      gtk-icon-theme-name = theme.iconTheme.name;
    }
    // optionalAttrs (theme.cursorTheme != null) {
      gtk-cursor-theme-name = theme.cursorTheme.name;
    }
    // optionalAttrs
    (theme.cursorTheme != null && theme.cursorTheme.size != null) {
      gtk-cursor-theme-size = theme.cursorTheme.size;
    };

  optionalPackage = opt:
    optional (opt != null && opt.package != null) opt.package;
in {
  options = {
    copper.chroma.gtk = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable Gtk2/3/4 theming via Chroma.
        '';
      };

      flatpak.enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to apply the Gtk theme in Flatpak applications as well.
        '';
      };
    };
  };

  config = {
    copper.chroma.programs.gtk = {
      themeOptions = {
        theme = options.gtk.theme;
        iconTheme = options.gtk.iconTheme;
        cursorTheme = options.gtk.cursorTheme;
        colorScheme = mkOption {
          type = types.enum ["default" "light" "dark"];
          default = "default";
          example = "dark";
          description = ''
            Whether applications should default to a light or dark theme.
          '';
        };
        font = options.gtk.font;
        monospaceFont = options.gtk.font;
        documentFont = options.gtk.font;
      };
      activationCommand = {
        name,
        opts,
      }:
        ''
          ${pkgs.dconf}/bin/dconf load /org/gnome/desktop/interface/ < ${opts.files."dconf.ini"}
        ''
        + optionalString cfg.gtk.flatpak.enable ''
          # TODO: this should autorevert, ideally
          # TODO: what about the cursor theme?
          # TODO: this requires some initial setup, which we should probably perform as part of a Flatpak module
          # flatpak override --filesystem=$HOME/.themes
          # flatpak override --filesystem=$HOME/.icons
          # of course, this is not the appropriate command for a nix system
          ${pkgs.flatpak}/bin/flatpak --user override --env=GTK_THEME="${opts.theme.name}"
          ${pkgs.flatpak}/bin/flatpak --user override --env=ICON_THEME="${opts.iconTheme.name}"
        '';

      templates."gtk-3.0/settings.ini" = {
        name,
        opts,
      }:
        toGtk3Ini {Settings = gtkIniForTheme opts // {gtk-application-prefer-dark-theme = opts.colorScheme == "dark";};};

      templates."gtk-2.0/gtkrc" = {
        name,
        opts,
      }:
        concatMapStrings (l: l + "\n") (mapAttrsToList formatGtk2Option (gtkIniForTheme opts));

      themeConfig = {config, ...}: {
        files."dconf.ini" = pkgs.writeText "dconf.ini" (toDconfIni {
          "/" =
            dconfBaseSettings
            // optionalAttrs (config.font != null) {
              font-name = toFontString config.font;
            }
            // optionalAttrs (config.monospaceFont != null) {
              monospace-font-name = toFontString config.monospaceFont;
            }
            // optionalAttrs (config.documentFont != null) {
              monospace-font-name = toFontString config.documentFont;
            }
            // optionalAttrs (config.theme != null) {gtk-theme = config.theme.name;}
            // optionalAttrs (config.iconTheme != null) {
              icon-theme = config.iconTheme.name;
            }
            // optionalAttrs (config.cursorTheme != null) {
              cursor-theme = config.cursorTheme.name;
            }
            // optionalAttrs
            (config.cursorTheme != null && config.cursorTheme.size != null) {
              cursor-size = config.cursorTheme.size;
            };
        });
      };
    };
  };

  imports = [
    (mkIf (cfg.enable && cfg.gtk.enable) {
      assertions = [
        {
          assertion = !config.gtk.enable;
          message = "Chroma's GTK theming is mutually exclusive with the normal GTK module.";
        }
      ];

      xdg.configFile."gtk-2.0".source = config.lib.file.mkOutOfStoreSymlink "${cfg.themeFolder}/active/gtk/gtk-2.0";
      xdg.configFile."gtk-3.0".source = config.lib.file.mkOutOfStoreSymlink "${cfg.themeFolder}/active/gtk/gtk-3.0";
      # TODO: according to the Arch wiki, this may not be sufficient for GTK4, we may also need to set GTK_THEME
      xdg.configFile."gtk-4.0".source = config.lib.file.mkOutOfStoreSymlink "${cfg.themeFolder}/active/gtk/gtk-3.0";

      home.sessionVariables.GTK2_RC_FILES = "${config.xdg.configHome}/gtk-2.0/gtkrc";

      home.packages = concatLists (mapAttrsToList (name: opts: with opts.gtk; concatMap optionalPackage [theme iconTheme cursorTheme font monospaceFont documentFont]) cfg.themes);
    })
  ];

  # TODO: do we need an xsettings deamon for X11-based apps? are XCURSOR_* variables needed?
}
