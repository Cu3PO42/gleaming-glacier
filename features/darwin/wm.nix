{
  pkgs,
  lib,
  config,
  copper,
  ...
}: let
  toggleScratchpad = pkgs.writeScriptBin "toggle-scratchpad" ''
    #!${pkgs.nodejs-slim_20}/bin/node

    const MAX_WIDTH = 800;
    const MAX_HEIGHT = 600;
    const MIN_PAD_X = 200;
    const MIN_PAD_Y = 100;

    const { promisify } = require('node:util');
    const { execFile } = require('node:child_process');
    const execFilePromise = promisify(execFile);

    async function query(queryString) {
        const {stdout} = await execFilePromise("yabai", ["-m", "query", ...queryString.split(" ")]);
        return JSON.parse(stdout);
    }

    async function window(command) {
        return execFilePromise("yabai", ["-m", "window", ...command.split(" ")]);
    }

    function launchiTerm() {
        return new Promise((resolve, reject) => {
            const child = execFile("osascript", (error, stdout) => {
                if (error) reject(error);

                const words = stdout.split(" ");
                resolve(parseInt(words[words.length - 1]));
            });
            child.stdin.write(`
    tell application "iTerm2"
        create window with profile "Scratchpad"
    end tell
    `);
            child.stdin.end();
        });
    }

    function sleep(ms) {
        return new Promise((resolve) => setTimeout(() => resolve(), ms));
    }

    async function run() {
        let scratchpadTerminal = (await query("--windows")).find(w => w.title.startsWith("Scratchpad") && w.app == "iTerm2");
        let scratchpadId, isMinimized;
        if (!scratchpadTerminal) {
            scratchpadId = await launchiTerm();
            await sleep(1000);
            isMinimized = true;
            await window(`''${scratchpadId} --toggle topmost`);
            await window(`''${scratchpadId} --toggle float`);
        } else {
            scratchpadId = scratchpadTerminal.id;
            isMinimized = scratchpadTerminal["is-minimized"];
        }

        const displays = await query("--displays");
        const activeSpace = (await query("--spaces --space")).index;
        const activeDisplay = displays.find(d => d.spaces.findIndex(s => s === activeSpace) !== -1);

        if (isMinimized) {
            const dWidth = activeDisplay.frame.w;
            const dHeight = activeDisplay.frame.h;
            const w = Math.min(MAX_WIDTH, dWidth - 2 * MIN_PAD_X);
            const h = Math.min(MAX_HEIGHT, dHeight - 2 * MIN_PAD_Y);
            const x = (dWidth - w) / 2;
            const y = MIN_PAD_Y;

            await window(`''${scratchpadId} --space ''${activeSpace}`);
            await window(`--focus ''${scratchpadId}`);
            await window(`--resize abs:''${w}:''${h}`);
            await window(`--move abs:''${x}:''${y}`);
        } else {
            await window(`--minimize ''${scratchpadId}`);
        }
    }

    run();
  '';
in {
  services.yabai.enable = true;
  services.yabai.enableScriptingAddition = true;
  # Our config needs jq to be available. Unfortunately the yabai module does
  # not use the abstraction over path, so we need to copy over the values from
  # the module as well.
  launchd.user.agents.yabai.serviceConfig.EnvironmentVariables.PATH =
    lib.mkForce
    ((with pkgs; lib.strings.makeBinPath [config.services.yabai.package jq sketchybar]) + ":${config.environment.systemPath}");

  
  # enable system shortcuts for switching desktops via ctrl + 1-6 and others
  system.activationScripts.userDefaults.text = ''
    defaults import com.apple.symbolichotkeys ${../../config/hotkeys.plist}
  '';

  services.skhd.enable = true;
  # We need some additional settings that aren't available directly on the service config
  launchd.user.agents.skhd = {
    # skhd executes everything in the user's login shell, but we want bash for portability
    environment.SHELL = "/bin/bash";
    # our config needs jq
    path = with pkgs; [(lib.strings.makeBinPath [jq toggleScratchpad])];
  };
  # Add it to the path for easier config reloading
  environment.systemPackages = [
    pkgs.skhd
    toggleScratchpad
    # Used for sketchybar
    pkgs.glab
  ];

  services.sketchybar.enable = true;
  services.sketchybar.extraPackages = with pkgs; [
    jq
    gh
    glab
    copper.packages.ical-buddy
    copper.packages.ifstat
    copper.packages.sketchybar-helper
  ];

  homebrew.brews = [
    # The following packages, installed through various means are all
    # dependencies of the sketchybar config
    "switchaudio-osx"
  ];
  homebrew.casks = [
    "sf-symbols"
  ];

  fonts.fonts = with pkgs; [
    copper.packages.sketchybar-app-font
    copper.packages.liga-sfmono-nerd-font
    font-awesome
  ];

  system.defaults.NSGlobalDomain._HIHideMenuBar = true;
  system.defaults.dock.autohide = true;

  # All configuration is managed through Home-Manager.
}
