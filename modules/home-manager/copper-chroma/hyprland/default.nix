{
  config,
  origin,
  options,
  pkgs,
  copper,
  lib,
  ...
}:
with lib; let
  inherit (origin.self.lib.types) colorType;

  cfg = config.copper.chroma;
in {
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
        assertion = !(cfg.enable && config.copper.chroma.hyprland.enable) || config.wayland.windowManager.hyprland.enable;
        message = "Chroma's Hyprland integration only works when the Hyprland module is enabled";
      }
      {
        assertion = !(cfg.enable && config.copper.chroma.hyprland.enable) || config.copper.chroma.desktop.enable;
        message = "Chroma's desktop module is required for the Hyprland module.";
      }
    ];

    copper.chroma.programs.hyprland = {
      activationCommand = {
        name,
        opts,
      }: let
        cursor = cfg.themes.${name}.hyprland.hyprcursor;
      in optionalString (cursor != null) ''
        ${config.wayland.windowManager.hyprland.package}/bin/hyprctl setcursor ${cursor.name} ${toString cursor.size}
      '';

      reloadCommand = ''
        ( ${config.xdg.configFile."hypr/hyprland.conf".onChange} ) >/dev/null 2>&1
      '';

      themeOptions = {
        hyprcursor = mkOption {
          type = types.nullOr options.gtk.cursorTheme.type;
          default = null;
          description = ''
            The Hyprcursor theme to use for Hyprland and apps supporting
            server-side cursors. If none is specificd, it will be automatically
            built from the XCursor theme. However, Hyprcursor has many
            advantages, such as proper scaling.
          '';
        };

        colorOverrides = mkOption {
          type = with types; attrsOf colorType;
          default = {};
          description = ''
            Color overrides to apply to the palette-generated theme.
          '';
        };
      };

      themeConfig = {config, opts, ...}: {
        hyprcursor = let
          cursor = opts.desktop.cursorTheme;
        in mkIf (cursor != null) (mkDefault {
          package = let
            translate = theme: pkgs.stdenv.mkDerivation {
              pname = "${cursor.package.pname}-hyprcursor-${theme}";
              inherit (cursor.package) version;
              nativeBuildInputs = [pkgs.hyprcursor pkgs.xcur2png];

              src = cursor.package;
              dontUnpack = true;
              inherit theme;

              manifest = ''
                name = ${theme}
                version = ${cursor.package.version}
                description = Automatically translated theme
                cursors_directory = hyprcursors
              '';

              buildPhase = ''
                hyprcursor-util --extract "$src/share/icons/$theme" -o .
                extractDir="$PWD/extracted_$theme"
                echo "$manifest" > "$extractDir/manifest.hl"
                hyprcursor-util --create "$extractDir"'';

              installPhase = ''
                mkdir -p $out/share/icons
                for theme in theme_*; do
                  mv "$theme" "$out/share/icons/''${theme#theme_}"
                done
              '';
            };
            availableThemes = builtins.attrNames (builtins.readDir "${cursor.package}/share/icons");
          in pkgs.symlinkJoin {
            name = "${cursor.package.pname}-hyprcursor-${cursor.package.version}";
            paths = map translate availableThemes;
          };

          inherit (cursor) name size;
        });

        file."entry.conf".text = let
          inherit (opts.desktop) cursorTheme;
        in ''
          source = ${cfg.themeDirectory}/active/hyprland/theme.conf

          ${optionalString (cursorTheme != null) ''
          env=XCURSOR_THEME,${cursorTheme.name}
          env=XCURSOR_SIZE,${toString cursorTheme.size}
          ''}
          ${optionalString (opts.hyprland.hyprcursor != null) ''
          env=HYPRCURSOR_THEME,${opts.hyprland.hyprcursor.name}
          env=HYPRCURSOR_SIZE,${toString opts.hyprland.hyprcursor.size}
          ''}
        '';

        file."theme.conf" = {
          required = true;

          source = mkDefault (opts.palette.generateDynamic {
            template = ./theme.conf.dyn;
            paletteOverrides = config.colorOverrides;
          });
        };
      };
    };

    wayland.windowManager.hyprland = mkIf (cfg.enable && config.copper.chroma.hyprland.enable) {
      settings = {
        source = ["${cfg.themeDirectory}/active/hyprland/entry.conf"];
      };
    };

    home.packages = mkIf (cfg.enable && config.copper.chroma.hyprland.enable)
      (concatLists (mapAttrsToList (name: opts: with opts.hyprland; optional (hyprcursor != null && hyprcursor.package != null) hyprcursor.package) cfg.themes));
  };
}
