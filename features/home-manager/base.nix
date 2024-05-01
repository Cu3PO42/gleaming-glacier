{
  pkgs,
  config,
  ...
}: {
  imports = [
    ../common/nix-settings.nix
  ];

  # Reflects the version at the time of initial setup, do not update
  home.stateVersion = "22.11";

  # Persist Home Manager
  programs.home-manager.enable = true;

  # Set basic settings
  home.homeDirectory =
    if pkgs.lib.strings.hasSuffix "linux" pkgs.system
    then "/home/${config.home.username}"
    else "/Users/${config.home.username}";

  # Nix Flakes and Home-Manager often need Git
  programs.git.enable = true;

  # Automatically start new services
  systemd.user.startServices = "sd-switch";
}
