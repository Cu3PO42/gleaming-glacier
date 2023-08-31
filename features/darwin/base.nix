{
  inputs,
  outputs,
  lib,
  ...
}: {
  copper.feature.known-hashes.enable = lib.mkDefault true;

  # Auto-update Nix
  services.nix-daemon.enable = true;

  nix = {
    # Configure Nix in accordance with what the Determinate Systems installer sets
    settings = {
      # Setting this to true causes various build issues due to links.
      auto-optimise-store = false;
    };
    extraOptions = ''
      extra-nix-path = nixpkgs=flake:nixpkgs
      auto-allocate-uids = true
      build-users-group = nixbld
      experimental-features = nix-command flakes auto-allocate-uids
    '';
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    };

    registry.nixpkgs.flake = inputs.nixpkgs;
    nixPath = [
      "nixpkgs=/etc/channels/nixpkgs"
    ];
  };

  environment.etc."channels/nixpkgs".source = inputs.nixpkgs.outPath;

  nixpkgs.config = {
    allowUnfree = true;
  };
  # Add all of our own overlays
  nixpkgs.overlays = builtins.attrValues outputs.overlays;

  # Defines the version of Nix-Darwin at which point the config was created. DO NOT UPDATE.
  system.stateVersion = 4;
}
