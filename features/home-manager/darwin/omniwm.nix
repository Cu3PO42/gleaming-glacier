{lib, ...}: {
  # TODO: install shell completions
	copper.feature.darwin.skhd.enable = true;
	services.skhd.keybinds.binds = let
		mkBind = name: dispatch: { inherit name dispatch; };
		omni = command: "omniwmctl command ${command}";
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
		focusBinds = genDirections "Focus" "alt" mkBind {
			up = omni "focus up";
			down = omni "focus down";
			left = omni "focus left";
			right = omni "focus right";
		};
		resizeBinds = genDirections "Resize" "" mkBind {
			up = omni "resize up grow";
			down = omni "resize down shrink";
			left = omni "resize left shrink";
			right = omni "resize right grow";
		};
		moveBinds = genDirections "Move" "" mkBind {
			up = omni "move-window-up";
			down = omni "move-window-down";
			left = omni "move left";
			right = omni "move right";
		};
	in {
		"super alt f" = mkBind "Toggle Fullscreen" (omni "toggle-fullscreen");
		"ctrl alt x" = {
			name = "Leader keymap";
			submap.binds = {
				"n" = {
					name = "Navigate to Workspace";
					submap.binds = let
						nav = n: omni "switch-workspace ${n}";
					in gen1To10 "" (n: mkBind "Workspace ${n}" (nav n)) // {
						"t" = mkBind "Next Workspace" (omni "switch-workspace next");
						"d" = mkBind "Previous Workspace" (omni "switch-workspace prev");
						"b" = mkBind "Workspace Back and Forth" (omni "switch-workspace back-and-forth");
					};
				};
				"m" = {
					name = "Move Window or Column to Workspace";
					submap.binds =
						gen1To10 "shift" (n: mkBind "Column to Workspace ${n}" (omni "move-column-to-workspace ${n}"))
						// gen1To10 "" (n: mkBind "Window to Workspace ${n}" (omni "move-to-workspace ${n}")) // {
							"t" = mkBind "Move Window to Next Workspace" (omni "move-to-workspace down");
							"d" = mkBind "Move Window to Previous Workspace" (omni "move-to-workspace up");
						};
				};
				"q" = mkBind "Close Active Window" "skhd -k 'cmd + w'";
        # TODO: does not do anything
        /*
				"r" = {
					name = "Resize Active Window";
					submap = {
						remain = true;
						binds = resizeBinds // focusBinds;
					};
				};
        */
				"f" = mkBind "Toggle Float" (omni "toggle-focused-window-floating");
				"shift f" = mkBind "Toggle Fullscreen" (omni "toggle-fullscreen");
        # TODO: does not do anything
        /*
				"shift m" = {
					name = "Move Active Window";
					submap.binds = moveBinds // focusBinds;
				};
        */
				"t" = mkBind "Toggle Column Tabbed" (omni "toggle-column-tabbed");
				"s" = {
					name = "Create a Screenshot";
					submap.binds = {
						"a" = mkBind "All Monitors" "skhd -k 'cmd + shift - 3'";
						"d" = mkBind "Select Area" "skhd -k 'cmd + shift - 4'";
						"w" = mkBind "Select Window" "skhd -k 'cmd + shift - 4'; sleep 0.1; skhd -k 'space'";
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
						"b" = mkBind "Browser" "open -a 'Zen'";
						"a" = mkBind "Application Launcher" "skhd -k 'cmd + space'";
						"m" = mkBind "System Monitor" "open -a 'Activity Monitor'";
					};
				};
        # TODO: not using jankyborders anymore; also disable that in config
				"v" = {
					name = "Visual Controls";
					submap.binds = {
						"b" = mkBind "Enable Borders" "~/.config/borders/bordersrc";
						"d" = mkBind "Disable Borders" "borders width=0";
						"shift b" = mkBind "Toggle Workspace Bar" (omni "toggle-workspace-bar");
					};
				};
				"shift l" = mkBind "Lock Screen" "skhd -k 'ctrl + cmd + q'";
				"shift q" = {
					name = "Logout";
					submap.binds."y" = mkBind "Yes" "skhd -k 'cmd + shift + q'";
				};
				"shift p" = {
					name = "Power Menu";
					submap.binds."s" = mkBind "Sleep" "pmset sleepnow";
				};
				"shift s" = mkBind "Toggle Quake Terminal" (omni "toggle-quake-terminal");
				"c" = {
					name = "Column and Window Layout";
					submap.remain = true;
					submap.binds = {
						"c" = mkBind "Consume Window into Column" (omni "consume-window-into-column");
						"e" = mkBind "Expel Window from Column" (omni "expel-window-from-column");
						"t" = mkBind "Toggle Column Tabbed" (omni "toggle-column-tabbed");
						"w" = mkBind "Cycle Column Width" (omni "cycle-column-width forward");
						"shift w" = mkBind "Cycle Column Width Backward" (omni "cycle-column-width backward");
						"h" = mkBind "Cycle Window Height" (omni "cycle-window-height forward");
						"shift h" = mkBind "Cycle Window Height Backward" (omni "cycle-window-height backward");
						"b" = mkBind "Balance Sizes" (omni "balance-sizes");
					};
				};
        "o" = mkBind "Toggle Overview" (omni "toggle-overview");
        "p" = mkBind "Command Palette" (omni "open-command-palette");
				"b" = mkBind "Toggle Workspace Bar" (omni "toggle-workspace-bar");
			};
		};
	};
}