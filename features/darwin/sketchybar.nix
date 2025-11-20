{copper, pkgs, config, ...}: {
  services.sketchybar.enable = true;
  services.sketchybar.extraPackages = with pkgs; [
    jq
    gh
    glab
    bash # Newer bash is needed for the iCal plugin
    (if config.copper.feature.aerospace.enable then pkgs.aerospace else pkgs.yabai)
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

  launchd.user.agents.sketchybar.environment = {
    SKETCHYBAR_WM = if config.copper.feature.aerospace.enable then "aerospace" else "yabai";
  };

  fonts.packages = with pkgs; [
    copper.packages.sketchybar-app-font
    copper.packages.liga-sfmono-nerd-font
    font-awesome
  ];

  homebrew.brews = [
    "switchaudio-osx"
  ];

  homebrew.casks = [
    "sf-symbols"
  ];

  environment.systemPackages = with pkgs; [
    glab
    copper.packages.mac-wm-helpers
  ];
}