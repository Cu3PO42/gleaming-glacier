{
  lib,
  config,
  pkgs,
  options,
  copper,
  ...
}: with lib; let
  cfg = config.copper.feature.nixos.hyprland;
in {
  featureOptions = {
    defaultPolkitAgent.enable = mkEnableOption ''
      Include a simple default Polkit Agent. Currently this is Pantheon from
      Elementary.
    '';
  };

  config = {
    copper.file.config = lib.genAttrs ["hypr/animations.conf" "hypr/entry.conf" "hypr/keybindings.conf" "hypr/nvidia.conf" "hypr/windowrules.conf"] (n: "config/${n}");
    wayland.windowManager.hyprland = {
      enable = true;
      # TODO: this also installs a hyprland package, how does this conflict with the global install
      package = copper.inputs.hyprland;
      systemd.enable = true;
      # Needed so that waybar, etc. have a complete environment
      systemd.variables =
        options.wayland.windowManager.hyprland.systemd.variables.default
        ++ [
          "XDG_DATA_DIRS"
          "XDG_CONFIG_DIRS"
          "PATH"
        ];
      # TODO: nvidia patches are no longer needed, but does that extend to the nvidia conf file?
      settings.source = lib.mkMerge [(lib.mkIf false ["${config.xdg.configHome}/hypr/nvidia.conf"]) ["${config.xdg.configHome}/hypr/entry.conf"]];
      settings.exec-once = "[workspace special:terminal silent;float;center;size 1200 800] kitty";
      # Move/Resize windows with SUPER + mouse buttons
      settings.bindm = [
        "super,mouse:272,movewindow"
        "super,mouse:273,resizewindow"
      ];

      keybinds.binds = let
        mkBind = name: dispatch: { inherit name dispatch; };
        mkRepeatingBind = name: dispatch: {
          name = "${name} (Repeating)";
          dispatch = dispatch;
          repeat = true;
        };
        gen1To10 = mods: f: let
          g = n: { name = "${mods} ${toString (if n == 10 then "0" else toString n)}"; value = f (toString n); };
        in lib.listToAttrs (map g (lib.range 1 10));
        genDirections = prefix: mods: gen: commands: {
          "${mods} n" = gen "${prefix} Up" commands.up;
          "${mods} r" = gen "${prefix} Down" commands.down;
          "${mods} t" = gen "${prefix} Left" commands.left;
          "${mods} d" = gen "${prefix} Right" commands.right;

          "${mods} up" = gen "${prefix} Up" commands.up;
          "${mods} down" = gen "${prefix} Down" commands.down;
          "${mods} left" = gen "${prefix} Left" commands.left;
          "${mods} right" = gen "${prefix} Right" commands.right;
        };
        moveFocusBinds = genDirections "Move Focus" "alt" mkBind {
          "up" = "movefocus,u";
          "down" = "movefocus,d";
          "left" = "movefocus,l";
          "right" = "movefocus,r";
        };
      in {
        "super x" = {
          name = "Leader keymap";
          submap.binds = {
            "n" = {
              name = "Navigate to Workspace";
              submap.binds = gen1To10 "" (n: mkBind "Workspace ${n}" "workspace,${n}") // {
                "t" = mkBind "Next Workspace" "workspace,r+1";
                "d" = mkBind "Previous Workspace" "workspace,r-1";
                "e" = mkBind "Empty Workspace" "workspace,empty";
              };
            };
            "m" = {
              name = "Move Current Window to Workspace";
              submap.binds =
                gen1To10 "" (n: mkBind "Workspace ${n}" "movetoworkspace,${n}") //
                gen1To10 "shift" (n: mkBind "Workspace ${n} (silent)" "movetoworkspacesilent,${n}") // {
                  "t" = mkBind "Next Workspace" "movetoworkspace,r+1";
                  "d" = mkBind "Previous Workspace" "movetoworkspace,r-1";
                  "e" = mkBind "Empty Workspace" "movetoworkspace,empty";
                };
            };
            "q" = mkBind "Close Active Window" "killactive";
            "r" = {
              name = "Resize active window";
              submap = {
                remain = true;
                binds = genDirections "Resize" "" mkRepeatingBind {
                  up = "resizeactive,0 -10";
                  down = "resizeactive,0 10";
                  left = "resizeactive,-10 0";
                  right = "resizeactive,10 0";
                } // moveFocusBinds;
              };
            };
            "f" = mkBind "Toggle Float" "togglefloating";
            "shift f" = mkBind "Toggle Fullscreen" "fullscreen";
            "ctrl f" = mkBind "Toggle Fake Fullsrceen" "fakefullscreen";
            "shift m" = {
              name = "Move active window on workspace";
              submap.binds = genDirections "Move" "" mkBind {
                up = "movewindow,u";
                down = "movewindow,d";
                left = "movewindow,l";
                right = "movewindow,r";
              } // moveFocusBinds;
            };
            "t" = mkBind "Toggle Split Direction" "togglesplit";
            "s" = {
              name = "Create a screenshot";
              submap.binds = {
                "m" = mkBind "Current Monitor" "exec,${copper.packages.misc-scripts-hyprdots}/bin/screenshot.sh m";
                "a" = mkBind "All Monitors" "exec,${copper.packages.misc-scripts-hyprdots}/bin/screenshot.sh p";
                "d" = mkBind "Select Area" "exec,${copper.packages.misc-scripts-hyprdots}/bin/screenshot.sh s";
              };
            };
            "l" = {
              name = "Launch Applications";
              submap.binds = {
                "t" = mkBind "Terminal" "exec,kitty";
                "c" = mkBind "VS Code" "exec,code";
                "f" = mkBind "File Manager" "exec,nautilus";
                "b" = mkBind "Browser" "exec,firefox";
                "a" = mkBind "Application Launcher" "exec,pkill -x rofi || rofilaunch.sh d";
                "m" = mkBind "System Monitor" "exec,[float;size 1100 800] kitty -e btop";
                "shift f" = mkBind "Browse System Files" "exec,pkill -x rofi || rofilaunch.sh f";
                "s" = mkBind "Application Switcher" "exec,pkill -x rofi || rofilaunch.sh w";
                "shift c" = mkBind "Clipboard History" "exec,pkill -x rofi || cliphist.sh c";
              };
            };
            "v" = {
              name = "Visual Controls";
              submap.binds = {
                "t" = mkBind "Select Theme" "exec,pkill -x rofi || themeselect.sh";
                "r" = mkBind "Select Rofi Style" "exec,pkill -x rofi || rofiselect.sh";
                "w" = mkBind "Select Wallpaper" "exec,pkill -x rofi || swwwallselect.sh";
                "leftarrow" = mkBind "Previous Wallpaper" "exec,swimctl previous" // { remain = true; };
                "rightarrow" = mkBind "Next Wallpaper" "exec,swimctl next" // { remain = true; };
              };
            };
            "shift l" = mkBind "Lock Screen" "exec,loginctl lock-session";
            "shift q" = {
              name = "Quit Hyprland";
              submap.binds."y" = mkBind "Yes" "exit";
            };
            "shift p" = mkBind "Power Menu" "exec,wlogout-launcher-hyprland 1";
            "p" = mkBind "Pin on all workspaces" "pin,active";
            "shift s" = mkBind "Toggle Scratchpad Terminal" "togglespecialworkspace,terminal";
            "g" = {
              name = "Create Groups";
              submap.binds = {
                "t" = mkBind "Toggle Group on the active window" "togglegroup";
                "o" = mkBind "Take active window out of group" "moveoutofgroup";
                "i" = {
                  name = "Move into Group in Direction";
                  submap.binds = genDirections "" "" mkBind {
                    up = "moveintogroup,u";
                    down = "moveintogroup,d";
                    left = "moveintogroup,l";
                    right = "moveintogroup,r";
                  };
                };
                "n" = mkBind "Cycle next in group" "changegroupactive,f" // { remain = true; };
                "p" = mkBind "Cycle previous in group" "changegroupactive,b" // { remain = true; };
              };
            };
            "b" = mkBind "Toggle Bar" "exec,systemctl-toggle --user waybar.service";
          };
        };
        "super ctrl shift alt q" = mkBind "Quit Hyprland" "exit" // { global = true; activeWhileLocked = true; };
        "super mouse_down" = mkBind "Move to next Workspace" "workspace,e+1";
        "super mouse_up" = mkBind "Move to previous Workspace" "workspace,e-1";
      };
    };

    home.packages = [copper.packages.systemctl-toggle pkgs.procps pkgs.btop pkgs.cliphist pkgs.wl-clipboard];

    systemd.user.services.polkit-authentication-agent = mkIf cfg.defaultPolkitAgent.enable {
      Unit = {
        Description = "Polkit authentication agent";
        Documentation = "https://gitlab.freedesktop.org/polkit/polkit/";
        After = ["graphical-session-pre.target"];
        PartOf = ["graphical-session.target"];
      };

      Service = {
        ExecStart = "${pkgs.pantheon.pantheon-agent-polkit}/libexec/policykit-1-pantheon/io.elementary.desktop.agent-polkit";
        Restart = "always";
        # TODO: dbus activation isn't working for the Gnome or Elementary (Pantheon) Agent for some reason
        #BusName = "org.freedesktop.PolicyKit1.AuthenticationAgent";
      };

      Install.WantedBy = ["hyprland-session.target"];
    };
    copper.desktopEnvironment.polkitAgent = mkIf cfg.defaultPolkitAgent.enable "pantheon";

    systemd.user.services.argyrodite.Install.WantedBy = ["hyprland-session.target"];
    systemd.user.services.asztal.Install.WantedBy = ["hyprland-session.target"];

    systemd.user.services.hyprdots-batterynotify = {
      Unit = {
        Description = "Battery notification from hyprdots";
        Documentation = "https://github.com/prasanthrangan/hyprdots";
        After = ["graphical-session-pre.target"];
        PartOf = ["graphical-session.target"];
      };

      Service = {
        ExecStart = "${copper.packages.misc-scripts-hyprdots}/bin/batterynotify.sh";
        Restart = "always";
      };

      Install.WantedBy = ["hyprland-session.target"];
    };

    systemd.user.services.chroma-launch = {
      Unit = {
        Description = "Set up theming scripts";
        After = ["graphical-session-pre.target"];
      };

      Service = {
        Type = "oneshot";
        ExecStart = "${config.copper.chroma.themeDirectory}/active/activate";
        Restart = "always";
      };

      Install.WantedBy = ["hyprland-session.target"];
    };

    services.network-manager-applet.enable = true;
    services.blueman-applet.enable = true;

    programs.kitty.enable = true;
    programs.kitty.font.name = "CaskaydiaCove Nerd Font Mono";
    programs.kitty.extraConfig = ''
      window_padding_width 5
    '';
  };
}
