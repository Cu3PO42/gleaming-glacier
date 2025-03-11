{
  config,
  lib,
  origin,
  ...
}: {
  imports = [
    ../common/nix-settings.nix
  ];

  copper.feature.known-hashes.enable = lib.mkDefault true;

  nix = {
    enable = true;
    # Configure Nix in accordance with what the Determinate Systems installer sets
    settings = {
      # Setting this to true causes various build issues due to links.
      auto-optimise-store = false;

      trusted-users = [config.defaultUser];
    };
    extraOptions = ''
      auto-allocate-uids = true
      build-users-group = nixbld
      experimental-features = nix-command flakes auto-allocate-uids
    '';
  };

  nixpkgs.overlays = [ origin.config.flake.overlays.updates ];

  # Defines the version of Nix-Darwin at which point the config was created.
  # Since this is a host-specific value and must not be updated, it needs to be
  # included in the host configuration. This default was erroneously included
  # here. It should not be relied upon.
  system.stateVersion = let
    msg = "You should always set `system.stateVersion` yourself because it is a host-specific property. Relying on a default is incorrect.";
  in lib.mkDefault (lib.warn msg 4);
}
