{
  lib,
  inputs,
  hmSpecialArgs,
  hmBaseModules,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  # Use the same nixpkgs as the system config
  home-manager.useGlobalPkgs = false;
  # Store user packages in $HOME
  home-manager.useUserPackages = false;
  # TODO: this is an extremely ad-hoc solution. could we inject the whole Flake config instead?
  home-manager.extraSpecialArgs = hmSpecialArgs;

  home-manager.sharedModules =
    hmBaseModules
    ++ [{
      copper.feature.nixosBase.enable = lib.mkDefault true;
      copper.feature.standaloneBase.enable = false;
    }];
}
