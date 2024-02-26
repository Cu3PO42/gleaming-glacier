{config, lib, ...}: {
  programs.skhd.enable = true;
  programs.skhd.keybinds.binds = let
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
      move = dir: "yabai -m window --focus ${dir} || yabai -m display --focus ${dir}";
    in {
      "up" = move "north";
      "down" = move "south";
      "left" = move "west";
      "right" = move "east";
    });
  in {
    "ctrl alt x" = {
      name = "Leader keymap";
      submap.binds = {
        "n" = {
          name = "Navigate to Workspace";
          submap.binds = let
            nav = n: "SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n \${SPACES[$((${n} - 1))]} ]] && spacectl switch \${SPACES[$((${n} - 1))]}";
          in gen1To10 "" (n: mkBind "Workspace ${n}" (nav n)) // {
            "t" = mkBind "Next Workspace" "spacectl next";
            "d" = mkBind "Previous Workspace" "spacectl previous";
            #"e" = mkBind "Empty Workspace" "workspace,empty";
          };
        };
        "m" = {
          name = "Move Current Window to Workspace";
          submap.binds = let
            mv = n: ''SPACES=($(yabai -m query --displays --display | jq '.spaces[]')) && [[ -n ''${SPACES[$((${n} - 1))]} ]] && yabai -m window --space ''${SPACES[$((${n} - 1))]} && sketchybar --trigger windows_on_spaces'';
          in
            #gen1To10 "" (n: mkBind "Workspace ${n}" "movetoworkspace,${n}") //
            gen1To10 "shift" (n: mkBind "Workspace ${n} (silent)" (mv n)) /*// {
              "t" = mkBind "Next Workspace" "movetoworkspace,r+1";
              "d" = mkBind "Previous Workspace" "movetoworkspace,r-1";
              "e" = mkBind "Empty Workspace" "movetoworkspace,empty";
            }*/;
        };
        "q" = mkBind "Close Active Window" "killactive";
        "r" = {
          name = "Resize active window";
          submap = {
            remain = true;
            binds = genDirections "Resize" "" mkBind (let
              res = side: opposite: geo: "yabai -m window --resize ${side}:${geo} || yabai -m window --resize ${opposite}:${geo}";
            in {
              up = res "bottom" "top" "0:-100";
              down = res "bottom" "top" "0:100";
              left = res "right" "left" "-100:0";
              right = res "right" "left" "100:0";
            }) // moveFocusBinds;
          };
        };
        "f" = mkBind "Toggle Float" "yabai -m window --toggle float; sketchybar --trigger window_focus";
        # TODO: make sure this is consistent with hyprland behavior
        "shift f" = mkBind "Toggle Fullscreen" "yabai -m window --toggle zoom-fullscreen; sketchybar --trigger window_focus";
        #"ctrl f" = mkBind "Toggle Fake Fullsrceen" "fakefullscreen";
        "shift m" = {
          name = "Move active window on workspace";
          submap.binds = genDirections "Move" "" mkBind {
            up = "yabai -m window --warp north || $(yabai -m window --display north && sketchybar --trigger windows_on_spaces && yabai -m display --focus north) || yabai -m window --move rel:0:-10";
            down = "yabai -m window --warp south || $(yabai -m window --display south && sketchybar --trigger windows_on_spaces && yabai -m display --focus south) || yabai -m window --move rel:0:10";
            left = "yabai -m window --warp west || $(yabai -m window --display west && sketchybar --trigger windows_on_spaces && yabai -m display --focus west && yabai -m window --warp last) || yabai -m window --move rel:-10:0";
            right = "yabai -m window --warp east || $(yabai -m window --display east && sketchybar --trigger windows_on_spaces && yabai -m display --focus east && yabai -m window --warp first) || yabai -m window --move rel:10:0";
          } // moveFocusBinds;
        };
        "t" = mkBind "Toggle Split Direction" "yabai -m window --toggle split";
        "s" = {
          name = "Create a screenshot";
          submap.binds = {
            #"m" = mkBind "Current Monitor" "exec,screenshot.sh m";
            "a" = mkBind "All Monitors" "skhd -k 'cmd + shift - 3'";
            "d" = mkBind "Select Area" "skhd -k 'cmd + shift - 4'";
            "w" = mkBind "Select Window" "skhd -k 'cmd + shift - 4'; sleep 0.1; skhd -k 'space'";
            # These are now for skhd
            "ctrl a" = mkBind "All Monitors (clipboard)" "skhd -k 'ctrl + cmd + shift - 3'";
            "ctrl d" = mkBind "Select Area (clipboard)" "skhd -k 'ctrl + cmd + shift - 4'";
            "ctrl w" = mkBind "Select Window (clipboard)" "skhd -k 'ctrl + cmd + shift - 4'; sleep 0.1; skhd -k 'space'";
          };
        };
        "l" = {
          name = "Launch Applications";
          submap.binds = {
            "t" = mkBind "Terminal" "open-iterm-window";
            "c" = mkBind "VS Code" "code";
            "f" = mkBind "File Manager" "open -a Finder";
            "b" = mkBind "Browser" "open -a 'Orion RC'";
            "a" = mkBind "Application Launcher" "skhd -k 'cmd + space'";
            "m" = mkBind "System Monitor" "open -a 'Activity Monitor'";
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
            "b" = mkBind "Enable Borders" "~/.config/borders/bordersrc";
            "d" = mkBind "Disable Borders" "borders width=0";
          };
        };
        "shift l" = mkBind "Lock Screen" "skhd -k 'ctrl + cmd + q'";
        "shift q" = {
          name = "Logout";
          submap.binds."y" = mkBind "Yes" "skhd -k 'cmd + shift + q'";
        };
        #"shift p" = mkBind "Power Menu" "exec,wlogout-launcher-hyprland 1";
        #"p" = mkBind "Pin on all workspaces" "pin,active";
        # TODO: ideally start iterm if not already running
        "shift s" = mkBind "Toggle Scratchpad Terminal" "skhd -k 'cmd + shift + w'";
        "g" = {
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
        };
        "b" = mkBind "Toggle Bar" "sketchybar --bar hidden=toggle";

        # New binds from skhd
        "z" = mkBind "Zoom to parent node" "yabai -m window --toggle zoom-parent; sketchybar --trigger window_focus";
        "i" = {
          name = "Set Insertion Point for next window";
          submap.binds = genDirections "Insert" "" mkBind (let
            insert = dir: "yabai -m window --insert ${dir}";
          in {
            up = insert "north";
            down = insert "south";
            left = insert "west";
            right = insert "east";
          });
        };
        "w" = {
          name = "Window Management commands";
          submap.binds = {
            x = mkBind "Mirror X" "yabai -m window --mirror x";
            y = mkBind "Mirror Y" "yabai -m window --mirror y";
            b = mkBind "Balance" "yabai -m window --balance";
          };
        };
      };
    };
  };
  copper.file.config."sketchybar" = "config/sketchybar";
  copper.file.config."yabai" = "config/yabai";
}
