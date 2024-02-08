{origin, pkgs, config, ...}: {
  home.stateVersion = "22.11";
  
  nixpkgs.config.allowUnfree = true;
  # Workaround for the above setting not working.
  nixpkgs.config.allowUnfreePredicate = _: true;

  # Persist Home Manager
  programs.home-manager.enable = true;

  # Set basic settings
  home.homeDirectory =
    if pkgs.lib.strings.hasSuffix "linux" pkgs.system
    then "/home/${config.home.username}"
    else "/Users/${config.home.username}";

  # Nix Flakes and Home-Manager often need Git
  programs.git.enable = true;
}
