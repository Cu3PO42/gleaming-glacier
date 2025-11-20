{
  copper,
  config,
  pkgs,
  lib,
  ...
}: {
  system.defaults.NSGlobalDomain._HIHideMenuBar = true;
  system.defaults.dock.autohide = true;

  environment.systemPackages = with pkgs; [
    jankyborders
    copper.packages.mac-wm-helpers
  ];

  # Sketchybar and yabai were previously both configured here.
  # For backwards compatibility, keep them on by default.
  # The reason for refactoring was adding aerospace support, so any user who has
  # that enabled is on the new system and does not need implicit yabai.
  copper.feature.sketchybar.enable = lib.mkDefault true;
  copper.feature.yabai.enable = lib.mkDefault (!config.copper.feature.aerospace.enable);
}
