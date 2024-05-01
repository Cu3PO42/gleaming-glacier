{
  config,
  lib,
  ...
}: {
  imports = [
    ../common/nix-settings.nix
  ];

  copper.feature.known-hashes.enable = lib.mkDefault true;

  # Auto-update Nix
  services.nix-daemon.enable = true;

  nix = {
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

  # Defines the version of Nix-Darwin at which point the config was created. DO NOT UPDATE.
  system.stateVersion = 4;
}
