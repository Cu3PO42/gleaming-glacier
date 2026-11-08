{
  main = {
    defaultUser = "Cu3PO42";
    copper.features = [
      "apps"
      "cli"
      "finder"
      "fish"
      "install-brew"
      "mouse"
      "orb-builder"
      "keyboard"
    ];
    copper.feature.yabai.enable = false;
    copper.feature.sketchybar.enable = false;
    nixpkgs.hostPlatform = "aarch64-darwin";
    system.stateVersion = 4;
  };
}
