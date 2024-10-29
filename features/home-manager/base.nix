{
  pkgs,
  config,
  lib,
  origin,
  ...
}: {
  imports = [
    ../common/nix-settings.nix
  ];

  # This value determines the Home-Manager release with which your
  # configuration was installed. This value is host-specic and should never be
  # updated for a particular installation. Thus, it should be set in the user
  # configuration and not a feature module. It was erroneously defined here in
  # the past. This default is deprecated.
  home.stateVersion = let
    msg = "You should always set `home.stateVersion` yourself because it is a configuration-specific property. Relying on a default is incorrect.";
  in lib.mkDefault (lib.warn msg "22.11");

  # Persist Home Manager
  programs.home-manager.enable = true;

  # Set basic settings
  home.homeDirectory =
    if pkgs.lib.strings.hasSuffix "linux" pkgs.system
    then "/home/${config.home.username}"
    else "/Users/${config.home.username}";

  # Nix Flakes and Home-Manager often need Git
  programs.git.enable = true;

  nixpkgs.overlays = [ origin.config.flake.overlays.updates ];

  # Automatically start new services
  systemd.user.startServices = "sd-switch";
}
