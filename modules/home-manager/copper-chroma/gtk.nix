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

  dconfBaseSettings = {
    font-antialiasing = "rgba";
    font-hinting = "full";
  };

  toFontString = font: let
    fontSize = optionalString (font.size != null) " ${toString font.size}";
  in
    "${font.name}" + fontSize;

  gtkIniForTheme = base: theme:
    base
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
        default = false;
        description = ''
          Whether to enable Gtk2/3/4 theming via Chroma.
        '';
      };

      gtk2.extraConfig = mkOption {
        type = with types; attrsOf (oneOf [bool int str (submodule { options.constant = mkOption {
          type = types.str;
          example = "GTK_TOOLBAR_ICONS";
          description = ''
            A constant to be used as the value of this option.
            It is not quoted and needs to be defined in GTK.
          '';
        }; })]);
        # TODO: move the default settings elsewhere
        default = options.copper.chroma.gtk.gtk3.extraConfig.default // {
          gtk-toolbar-style = mkIntConstant "GTK_TOOLBAR_ICONS";
          gtk-toolbar-icon-size = mkIntConstant "GTK_ICON_SIZE_LARGE_TOOLBAR";
          gtk-button-images = 0;
          gtk-menu-images = 0;
        };
        example = {
          gtk-can-change-accels = 1;
        };
        description = ''
          Extra configuration options to add to
          {file}`$XDG_CONFIG_HOME/gtk-2.0/gtkrc`.
        '';
      };

      gtk3.extraConfig = mkOption {
        type = options.copper.chroma.gtk.gtk2.extraConfig.type;
        # TODO: move the default settings elsewhere
        default = {
          gtk-enable-event-sounds = 1;
          gtk-enable-input-feedback-sounds = 0;
          gtk-xft-antialias = 1;
          gtk-xft-hinting = 1;
          gtk-xft-hintstyle = "hintfull";
          gtk-xft-rgba = "rgb";
        };
        example = {
          gtk-cursor-blink = false;
          gtk-recent-files-limit = 20;
        };
        description = options.gtk.gtk3.extraConfig.description;
      };

      gtk4 = {
        libadwaitaSupport = mkOption {
          type = types.enum ["off" "import" "patch-overlay" "patch-binary"];
          default = "off";
          example = "patch-binary";
          description = ''
            By default, libadwaita does not support any non-adwaita themes.
            This can be worked around by either patching libadwaita or by
            creating additional CSS imports.

            While CSS imports will work for most applications, they may break
            hot theme reloading. Patching libadwaita is recommended for dynamic
            theme switching, but will only work for apps installed via
            Home-Manager. You can either use an overlay, which causes a lot of
            rebuilds or binary patching, which is recommended while not
            supported by upstream Home-Manager. The latter might also miss a
            package in rare circumstances.
          '';
        };

        extraConfig = options.copper.chroma.gtk.gtk3.extraConfig // {
          description = options.gtk.gtk4.extraConfig.description;
        };
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
        colorScheme = mkOption {
          type = types.enum ["default" "prefer-light" "prefer-dark"];
          default = "default";
          example = "dark";
          description = ''
            Whether applications should default to a light or dark theme.
          '';
        };
        documentFont = options.gtk.font;
      };
      activationCommand = {
        name,
        opts,
      }:
        ''
          ${pkgs.dconf}/bin/dconf load /org/gnome/desktop/interface/ < ${opts.file."dconf.ini".source}
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
      
      reloadCommand = "${lib.getExe pkgs.gtkrc-reload}";

      themeConfig = {config, opts, ...}: {
        file."gtk-3.0/settings.ini".text =
          toGtk3Ini {Settings = gtkIniForTheme cfg.gtk.gtk3.extraConfig (config // opts.desktop) // {gtk-application-prefer-dark-theme = config.colorScheme == "prefer-dark";};};

        file."gtk-4.0/settings.ini".text =
          toGtk3Ini {Settings = gtkIniForTheme cfg.gtk.gtk4.extraConfig (config // opts.desktop) // {gtk-application-prefer-dark-theme = config.colorScheme == "prefer-dark";};};

        file."gtk-4.0/gtk.css".text = mkIf (cfg.gtk.gtk4.libadwaitaSupport == "import") ''
          @import url("file://${config.theme.package}/share/themes/${config.theme.name}/gtk-4.0/gtk.css");
        '';

        file."gtk-2.0/gtkrc".text =
          concatMapStrings (l: l + "\n") (mapAttrsToList formatGtk2Option (gtkIniForTheme cfg.gtk.gtk2.extraConfig (config // opts.desktop)));

        file."dconf.ini".text = toDconfIni {
          "/" =
            dconfBaseSettings
            // {
              color-scheme = config.colorScheme;
            }
            // optionalAttrs (opts.desktop.font != null) {
              font-name = toFontString opts.desktop.font;
            }
            // optionalAttrs (opts.desktop.monospaceFont != null) {
              monospace-font-name = toFontString opts.desktop.monospaceFont;
            }
            // optionalAttrs (config.documentFont != null) {
              monospace-font-name = toFontString config.documentFont;
            }
            // optionalAttrs (config.theme != null) {gtk-theme = config.theme.name;}
            // optionalAttrs (opts.desktop.iconTheme != null) {
              icon-theme = opts.desktop.iconTheme.name;
            }
            // optionalAttrs (opts.desktop.cursorTheme != null) {
              cursor-theme = opts.desktop.cursorTheme.name;
            }
            // optionalAttrs
            (opts.desktop.cursorTheme != null && opts.desktop.cursorTheme.size != null) {
              cursor-size = opts.desktop.cursorTheme.size;
            };
        };
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
        {
          assertion = cfg.desktop.enable;
          message = "Chroma's desktop module is required for the GTK module.";
        }
      ];

      copper.chroma.desktop.enable = true;

      xdg.configFile."gtk-2.0".source = config.lib.file.mkOutOfStoreSymlink "${cfg.themeFolder}/active/gtk/gtk-2.0";
      xdg.configFile."gtk-3.0".source = config.lib.file.mkOutOfStoreSymlink "${cfg.themeFolder}/active/gtk/gtk-3.0";
      xdg.configFile."gtk-4.0".source = config.lib.file.mkOutOfStoreSymlink "${cfg.themeFolder}/active/gtk/gtk-4.0";

      home.sessionVariables.GTK2_RC_FILES = "${config.xdg.configHome}/gtk-2.0/gtkrc";

      home.packages = concatLists (mapAttrsToList (name: opts: with opts.gtk; concatMap optionalPackage [theme documentFont]) cfg.themes);

      nixpkgs.overlays = mkIf (cfg.gtk.gtk4.libadwaitaSupport == "patch-overlay") [
        (final: prev: {
          # We cannot use libadwaita-without-adwaita that is added via the
          # overlay, as that package itself relies on libadwaita, which would
          # cause an inifinite recursion here.
          libadwaita = pkgs.callPackage ../../../packages/libadwaita-without-adwaita {libadwaita = prev.libadwaita;};
        })
      ];

      home.replaceRuntimeDependencies = mkIf (cfg.gtk.gtk4.libadwaitaSupport == "patch-binary") [
        {
          original = pkgs.libadwaita;
          replacement = pkgs.libadwaita-without-adwaita;
        }
      ];
    })
  ];

  # TODO: do we need an xsettings deamon for X11-based apps? are XCURSOR_* variables needed?
}
