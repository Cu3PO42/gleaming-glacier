{
  config,
  pkgs,
  lib,
  ...
}: {
  neo2.enable = true;
  # Install using Homebrew rather than Nix, since there were issues with the Nix version.
  homebrew.casks = [
    "karabiner-elements"
  ];
  # Allows switching between QWERTZ for my Moonlander and Neo for everything else
  services.autokbisw.enable = true;

  # Ideally, we'd like to enable the keyboard layouts Neo2 and Unicode Hex Input
  # Also, we want to enable the hotkeys for switching layouts. This can be done
  # using the settings
  #   "com.apple.symbolichotkeys".AppleSymbolicHotKeys."60.enable" = true;
  #   "com.apple.symbolichotkeys".AppleSymbolicHotKeys."61.enable" = true;
  # Unfortunately, these cannot be set using system.defaults because it is a
  # nested update, which is not supported by defaults write.
  system.defaults.NSGlobalDomain = {
    InitialKeyRepeat = 15;
    KeyRepeat = 2;
  };
}
