{
  inputs,
  outputs,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  # Use the same nixpkgs as the system config
  home-manager.useGlobalPkgs = false;
  # Store user packages in $HOME
  home-manager.useUserPackages = false;
  home-manager.extraSpecialArgs = {
    inherit inputs outputs;
  };

  home-manager.sharedModules =
    builtins.attrValues outputs.homeModules
    ++ [
      {copper.feature.nixosBase.enable = true;}
    ];
}
