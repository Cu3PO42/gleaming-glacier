{
  pkgs,
  lib,
  config,
  copper,
  ...
}: {
  services.yabai.enable = true;
  services.yabai.enableScriptingAddition = false;
  # Our config needs jq to be available. Unfortunately the yabai module does
  # not use the abstraction over path, so we need to copy over the values from
  # the module as well.
  launchd.user.agents.yabai.serviceConfig.EnvironmentVariables.PATH =
    lib.mkForce
    # Add the aarch64 Homebrew bin path, which is where we install borders. For x64, the path is /usr/local/bin, which is in the system path by default.
    ((with pkgs; lib.strings.makeBinPath [config.services.yabai.package jq sketchybar]) + ":${config.environment.systemPath}:/opt/homebrew/bin");

  
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
    path = with pkgs; [
      (lib.strings.makeBinPath [yabai jq sketchybar copper.packages.mac-wm-helpers skhd])
      config.environment.systemPath
      "/opt/homebrew/bin"
    ];
    # For debugging
    serviceConfig = {
      StandardOutPath = "/tmp/skhd.out.log";
      StandardErrorPath = "/tmp/skhd.err.log";
    };
  };
  # Add it to the path for easier config reloading
  environment.systemPackages = [
    pkgs.skhd
    # Used for sketchybar
    pkgs.glab
    copper.packages.mac-wm-helpers
  ];

  services.sketchybar.enable = true;
  services.sketchybar.extraPackages = with pkgs; [
    jq
    gh
    glab
    bash # Newer bash is needed for the iCal plugin
    copper.packages.ical-buddy
    copper.packages.ifstat
    copper.packages.sketchybar-helper
    copper.packages.mac-wm-helpers
  ];

  # Keep process logs for debugging
  launchd.user.agents.sketchybar.serviceConfig = {
    StandardOutPath = "/tmp/sketchybar.out.log";
    StandardErrorPath = "/tmp/sketchybar.err.log";
  };

  homebrew.taps = [
    # This is the source for borders
    "felixkratz/formulae"
  ];
  homebrew.brews = [
    # The following packages, installed through various means are all
    # dependencies of the sketchybar or yabai config
    "switchaudio-osx"
    # We cannot build this via Nix because it needs a newer SDK than is
    # available. Also there are no prebuilt binaries available.
    "borders"
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
