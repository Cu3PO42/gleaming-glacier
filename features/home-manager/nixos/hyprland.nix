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
    copper.file.config = lib.genAttrs ["hypr/animations.lua" "hypr/entry.lua" "hypr/keybindings.lua" "hypr/nvidia.lua" "hypr/windowrules.lua" "hypr/1password.lua"] (n: "config/${n}");
    wayland.windowManager.hyprland = {
      enable = true;
      plugins = with pkgs.hyprlandPlugins; [
        # I wasn't really using hy3 anyway.
        #hy3
        # Currently broken upstream :( reenable soon!
        #hyprexpo
      ];
      systemd.enable = true;
      # Needed so that waybar, etc. have a complete environment
      systemd.variables =
        options.wayland.windowManager.hyprland.systemd.variables.default
        ++ [
          "XDG_DATA_DIRS"
          "XDG_CONFIG_DIRS"
          "PATH"
        ];
      configType = "lua";
      settings = {

      };
      extraConfig = ''
        hl.bind("SUPER + mouse:272", hl.dsp.window.drag())
        hl.bind("SUPER + mouse:273", hl.dsp.window.resize())

        hl.on("hyprland.start", function()
          hl.exec_cmd("kitty", { workspace = "special:terminal silent", float = true, center = "", size = "1200 800" })
        end)

        ${lib.optionalString (config.copper.feature.nixos._1password.enable) "require('${config.xdg.configHome}/hypr/1password.lua')"}
        require('${config.xdg.configHome}/hypr/entry.lua')
      '';

      keybinds.binds = let
        toLua = lib.generators.toLua {};
        mkDsp = name: args: "hl.dsp.${name}(${toLua args})";
        mkDspNoArgs = name: "hl.dsp.${name}()";
        mkExec = command: mkDsp "exec_cmd" command;
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
          "up" = mkDsp "focus" { direction = "u"; };
          "down" = mkDsp "focus" { direction = "d"; };
          "left" = mkDsp "focus" { direction = "l"; };
          "right" = mkDsp "focus" { direction = "r"; };
        };
      in {
        "super x" = {
          name = "Leader keymap";
          submap.binds = {
            "n" = {
              name = "Navigate to Workspace";
              submap.binds = gen1To10 "" (n: mkBind "Workspace ${n}" (mkDsp "focus" { workspace = n; })) // {
                "t" = mkBind "Next Workspace" (mkDsp "focus" { workspace = "r+1"; });
                "d" = mkBind "Previous Workspace" (mkDsp "focus" { workspace = "r-1"; });
                "e" = mkBind "Empty Workspace" (mkDsp "focus" { workspace = "empty"; });
              };
            };
            "m" = {
              name = "Move Current Window to Workspace";
              submap.binds =
                gen1To10 "" (n: mkBind "Workspace ${n}" (mkDsp "window.move" { workspace = n; })) //
                gen1To10 "shift" (n: mkBind "Workspace ${n} (silent)" (mkDsp "window.move" { workspace = n; follow = false; })) // {
                  "t" = mkBind "Next Workspace" (mkDsp "window.move" { workspace = "r+1"; });
                  "d" = mkBind "Previous Workspace" (mkDsp "window.move" { workspace = "r-1"; });
                  "e" = mkBind "Empty Workspace" (mkDsp "window.move" { workspace = "empty"; });
                };
            };
            "q" = mkBind "Close Active Window" (mkDspNoArgs "window.close");
            "r" = {
              name = "Resize active window";
              submap = {
                remain = true;
                binds = genDirections "Resize" "" mkRepeatingBind {
                  up = mkDsp "window.resize" { x = 0; y = -10; relative = true; };
                  down = mkDsp "window.resize" { x = 0; y = 10; relative = true; };
                  left = mkDsp "window.resize" { x = -10; y = 0; relative = true; };
                  right = mkDsp "window.resize" { x = 10; y = 0; relative = true; };
                } // moveFocusBinds;
              };
            };
            "f" = mkBind "Toggle Float" (mkDsp "window.float" { action = "toggle"; });
            "shift f" = mkBind "Toggle Fullscreen" (mkDsp "window.fullscreen" { mode = ""; action = "toggle"; });
            "ctrl f" = mkBind "Toggle Fake Fullsrceen" (mkDsp "window.fullscreen_state" { internal = -1; client = 2; action = "toggle"; });
            "shift m" = {
              name = "Move active window on workspace";
              submap.binds = genDirections "Move" "" mkBind {
                up = mkDsp "window.move" { direction = "u"; };
                down = mkDsp "window.move" { direction = "d"; };
                left = mkDsp "window.move" { direction = "l"; };
                right = mkDsp "window.move" { direction = "r"; };
              } // moveFocusBinds;
            };
            "t" = mkBind "Toggle Split Direction" (mkDsp "layout" "togglesplit");
            "s" = {
              name = "Create a screenshot";
              submap.binds = {
                "m" = mkBind "Current Monitor" (mkExec "${copper.packages.misc-scripts-hyprdots}/bin/screenshot.sh m");
                "a" = mkBind "All Monitors" (mkExec "${copper.packages.misc-scripts-hyprdots}/bin/screenshot.sh p");
                "d" = mkBind "Select Area" (mkExec "${copper.packages.misc-scripts-hyprdots}/bin/screenshot.sh s");
              };
            };
            "l" = {
              name = "Launch Applications";
              submap.binds = {
                "t" = mkBind "Terminal" (mkExec "kitty");
                "c" = mkBind "VS Code" (mkExec "code");
                "f" = mkBind "File Manager" (mkExec "nautilus");
                "b" = mkBind "Browser" (mkExec "firefox");
                "a" = mkBind "Application Launcher" (mkExec "pkill -x rofi || rofilaunch.sh d");
                "m" = mkBind "System Monitor" (mkExec "[float;size 1100 800] kitty -e btop");
                "shift f" = mkBind "Browse System Files" (mkExec "pkill -x rofi || rofilaunch.sh f");
                "s" = mkBind "Application Switcher" (mkExec "pkill -x rofi || rofilaunch.sh w");
                "shift c" = mkBind "Clipboard History" (mkExec "pkill -x rofi || cliphist.sh c");
              };
            };
            "v" = {
              name = "Visual Controls";
              submap.binds = {
                "t" = mkBind "Select Theme" (mkExec "pkill -x rofi || themeselect.sh");
                "r" = mkBind "Select Rofi Style" (mkExec "pkill -x rofi || rofiselect.sh");
                "w" = mkBind "Select Wallpaper" (mkExec "pkill -x rofi || swwwallselect.sh");
                "leftarrow" = mkBind "Previous Wallpaper" (mkExec "swimctl previous") // { remain = true; };
                "rightarrow" = mkBind "Next Wallpaper" (mkExec "swimctl next") // { remain = true; };
              };
            };
            "shift l" = mkBind "Lock Screen" (mkExec "loginctl lock-session");
            "shift q" = {
              name = "Quit Hyprland";
              submap.binds."y" = mkBind "Yes" (mkDspNoArgs "exit");
            };
            "shift p" = mkBind "Power Menu" (mkExec "wlogout-launcher-hyprland 1");
            "p" = mkBind "Pin on all workspaces" (mkDspNoArgs "window.pin");
            # Disable since the plugin is not installed currently.
            #"o" = mkBind "Workspace  overview" "hyprexpo:expo,toggle";
            "shift s" = mkBind "Toggle Scratchpad Terminal" (mkDsp "workspace.toggle_special" "terminal");
            "g" = {
              name = "Create Groups";
              submap.binds = {
                "t" = mkBind "Toggle Group on the active window" (mkDspNoArgs "group.toggle");
                "o" = mkBind "Take active window out of group" (mkDsp "window.move" { out_of_group = true; });
                "i" = {
                  name = "Move into Group in Direction";
                  submap.binds = genDirections "" "" mkBind {
                    up = mkDsp "window.move" { into_group = "u"; };
                    down = mkDsp "window.move" { into_group = "d"; };
                    left = mkDsp "window.move" { into_group = "l"; };
                    right = mkDsp "window.move" { into_group = "r"; };
                  };
                };
                "n" = mkBind "Cycle next in group" (mkDspNoArgs "group.next") // { remain = true; };
                "p" = mkBind "Cycle previous in group" (mkDspNoArgs "group.prev") // { remain = true; };
              };
            };
            "b" = mkBind "Toggle Bar" (mkExec "systemctl-toggle --user waybar.service");
            "alt p" = lib.mkIf (config.copper.feature.nixos._1password.enable) (mkBind "Toggle 1Password" (mkDsp "workspace.toggle_special" "password"));
          };
        };
        "super ctrl shift alt q" = mkBind "Quit Hyprland" (mkDspNoArgs "exit") // { global = true; activeWhileLocked = true; };
        "super mouse_down" = mkBind "Move to next Workspace" (mkDsp "focus" { workspace = "e+1"; });
        "super mouse_up" = mkBind "Move to previous Workspace" (mkDsp "focus" { workspace = "e-1"; });
      };
    };

    home.packages = with pkgs; [
      copper.packages.systemctl-toggle
      procps
      btop
      cliphist
      wl-clipboard
      pamixer
      brightnessctl
      playerctl
    ];

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

    systemd.user.services.argyrodite = mkIf config.copper.feature.nixos.argyrodite.enable {
      Install.WantedBy = ["hyprland-session.target"];
    };
    systemd.user.services.illogical-impulse = mkIf config.copper.feature.nixos.illogical-impulse.enable {
      Install.WantedBy = ["hyprland-session.target"];
    };

    copper.chroma.systemdTarget = "hyprland-session.target";

    services.network-manager-applet.enable = true;
    services.blueman-applet.enable = true;

    programs.kitty.enable = true;
    programs.kitty.font.name = "CaskaydiaCove Nerd Font Mono";
    programs.kitty.extraConfig = ''
      window_padding_width 5
    '';
  };
}
