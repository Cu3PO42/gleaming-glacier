{pkgs, lib, copper, config, ...}: {
  programs.aerospace = {
    enable = true;
    launchd.enable = true;
    userSettings = {
      "after-startup-command" = ["exec-and-forget borders"];
      gaps = {
        inner.horizontal = 10;
        inner.vertical = 10;
        outer.left = 10;
        outer.right = 10;
        outer.top = 18;
        outer.bottom = 10;
      };
    };
  };
  # We use skhd for keybindings, even though aerospace has built-in support,
  # because aerospace binds via key code rather than key symbol, which causes
  # problems with my mixed layouts.
  # See https://github.com/nikitabobko/AeroSpace/issues/1012
  copper.feature.darwin.skhd.enable = true;
  services.skhd = {
    extraPackages = with pkgs; [ copper.packages.mac-wm-helpers config.programs.aerospace.package sketchybar ];
    keybinds.binds = let
      mkBind = name: dispatch: { inherit name dispatch; };
      gen1To10 = mods: f: let
        g = n: { name = "${mods} ${toString (if n == 10 then "0" else toString n)}"; value = f (toString n); };
      in lib.listToAttrs (map g (lib.range 1 10));
      genDirections = prefix: mods: gen: commands: {
        "${mods} n" = gen "${prefix} Up" commands.up;
        "${mods} r" = gen "${prefix} Down" commands.down;
        "${mods} t" = gen "${prefix} Left" commands.left;
        "${mods} d" = gen "${prefix} Right" commands.right;

        "${mods} uparrow" = gen "${prefix} Up" commands.up;
        "${mods} downarrow" = gen "${prefix} Down" commands.down;
        "${mods} leftarrow" = gen "${prefix} Left" commands.left;
        "${mods} rightarrow" = gen "${prefix} Right" commands.right;
      };
      moveFocusBinds = genDirections "Move Focus" "alt" mkBind (let
        move = dir: "focus ${dir}";
      in {
        "up" = move "up";
        "down" = move "down";
        "left" = move "left";
        "right" = move "right";
      });

      #ae = c: c;
      #cmd = c: "exec-and-forget ${c}";
      ae = c: "aerospace ${c}";
      cmd = c: c;
    in {
      "super alt f" = mkBind "Toggle Fullscreen" (ae "layout tiling floating");
      "ctrl alt x" = {
        name = "Leader keymap";
        submap.binds = {
          "n" = {
            name = "Navigate to Workspace";
            submap.binds = let
              nav = n: (ae "workspace ${n}");
            in gen1To10 "" (n: mkBind "Workspace ${n}" (nav n)) // {
              "t" = mkBind "Next Workspace" (ae "workspace next");
              "d" = mkBind "Previous Workspace" (ae "workspace prev");
              #"e" = mkBind "Empty Workspace" (ae "workspace empty");
            };
          };
          "m" = {
            name = "Move Current Window to Workspace";
            submap.binds =
              gen1To10 "shift" (n: mkBind "Workspace ${n}" (ae "move-node-to-workspace ${n} --focus-follows-window")) //
              gen1To10 "" (n: mkBind "Workspace ${n} (silent)" (ae "move-node-to-workspace ${n}")) // {
                "t" = mkBind "Next Workspace" (ae "move-node-to-workspace next");
                "d" = mkBind "Previous Workspace" (ae "move-node-to-workspace prev");
                #"e" = mkBind "Empty Workspace" (ae "move-node-to-workspace empty");
              };
          };
          "q" = mkBind "Close Active Window" (ae "close");
          "r" = {
            name = "Resize active window";
            submap = {
              remain = true;
              binds = genDirections "Resize" "" mkBind (let
                res = dim: change: ae "resize ${dim} ${change}";
              in {
                up = res "height" "+100";
                down = res "height" "-100";
                left = res "width" "-100";
                right = res "width" "+100";
              }) // moveFocusBinds;
            };
          };
          "f" = mkBind "Toggle Float" (ae "layout tiling floating");
          "shift f" = mkBind "Toggle Fullscreen" (ae "fullscreen");
          "shift m" = {
            name = "Move active window on workspace";
            submap.binds = genDirections "Move" "" mkBind {
              up = ae "move up";
              down = ae "move down";
              left = ae "move left";
              right = ae "move right";
            } // moveFocusBinds;
          };
          "t" = mkBind "Toggle Split Direction" (ae "layout horizontal vertical");
          "s" = {
            name = "Create a screenshot";
            submap.binds = {
              #"m" = mkBind "Current Monitor" "exec,screenshot.sh m";
              "a" = mkBind "All Monitors" (cmd "skhd -k 'cmd + shift - 3'");
              "d" = mkBind "Select Area" (cmd "skhd -k 'cmd + shift - 4'");
              "w" = mkBind "Select Window" (cmd "skhd -k 'cmd + shift - 4'; sleep 0.1; skhd -k 'space'");
              # These are now for skhd
              "ctrl a" = mkBind "All Monitors (clipboard)" (cmd "skhd -k 'ctrl + cmd + shift - 3'");
              "ctrl d" = mkBind "Select Area (clipboard)" (cmd "skhd -k 'ctrl + cmd + shift - 4'");
              "ctrl w" = mkBind "Select Window (clipboard)" (cmd "skhd -k 'ctrl + cmd + shift - 4'; sleep 0.1; skhd -k 'space'");
            };
          };
          "l" = {
            name = "Launch Applications";
            submap.binds = {
              "t" = mkBind "Terminal" (cmd "open-iterm-window");
              "c" = mkBind "VS Code" (cmd "code");
              "f" = mkBind "File Manager" (cmd "open -a Finder");
              "b" = mkBind "Browser" (cmd "open -a 'Zen'");
              "a" = mkBind "Application Launcher" (cmd "skhd -k 'cmd + space'");
              "m" = mkBind "System Monitor" (cmd "open -a 'Activity Monitor'");
              #"shift f" = mkBind "Browse System Files" "exec,pkill -x rofi || rofilaunch.sh f";
              #"s" = mkBind "Application Switcher" "exec,pkill -x rofi || rofilaunch.sh w";
              #"shift c" = mkBind "Clipboard History" "exec,pkill -x rofi || cliphist.sh c";
            };
          };
          "v" = {
            name = "Visual Controls";
            submap.binds = {
              /*"t" = mkBind "Select Theme" "exec,pkill -x rofi || themeselect.sh";
              "r" = mkBind "Select Rofi Style" "exec,pkill -x rofi || rofiselect.sh";
              "w" = mkBind "Select Wallpaper" "exec,pkill -x rofi || swwwallselect.sh";
              "leftarrow" = mkBind "Previous Wallpaper" "swimctl previous" // { remain = true; };
              "rightarrow" = mkBind "Next Wallpaper" "swimctl next" // { remain = true; };
              */
              "b" = mkBind "Enable Borders" (cmd "~/.config/borders/bordersrc");
              "d" = mkBind "Disable Borders" (cmd "borders width=0");
            };
          };
          "shift l" = mkBind "Lock Screen" (cmd "skhd -k 'ctrl + cmd + q'");
          "shift q" = {
            name = "Logout";
            submap.binds."y" = mkBind "Yes" (cmd "skhd -k 'cmd + shift + q'");
          };
          "shift p" = {
            name = "Power Menu";
            submap.binds = {
              "s" = mkBind "sleep" (cmd "pmset sleepnow");
            };
          };
          #"p" = mkBind "Pin on all workspaces" "pin,active";
          # TODO: ideally start iterm if not already running
          "shift s" = mkBind "Toggle Scratchpad Terminal" (cmd "skhd -k 'cmd + shift + w'");
          /*"g" = {
            name = "Create Groups";
            submap.binds = {
              #"t" = mkBind "Toggle Group on the active window" "togglegroup";
              "o" = mkBind "Take active window out of group" "WINDOW=$(yabai -m query --windows --window | jq -r '.id') (yabai -m window --toggle float && yabai -m window --toggle float) && sketchybar --trigger window_focus";
              "i" = {
                name = "Move into Group in Direction";
                submap.binds = genDirections "" "" mkBind (let
                  move = dir: "yabai -m window ${dir} --stack $(yabai -m query --windows --window | jq -r '.id') && sketchybar --trigger window_focus";
                in {
                  up = move "north";
                  down = move "south";
                  left = move "west";
                  right = move "east";
                });
              };
              "n" = mkBind "Cycle next in group" "yabai -m window --focus stack.next" // { remain = true; };
              "p" = mkBind "Cycle previous in group" "yabai -m window --focus stack.prev" // { remain = true; };
            };
          };*/
          "b" = mkBind "Toggle Bar" (cmd "skhd -k 'cmd + alt + b'");

          # New binds from aerospace
        };
      };
    };
  };
}
