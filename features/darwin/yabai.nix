{
  pkgs,
  lib,
  config,
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

  # All configuration is managed through Home-Manager.
}
