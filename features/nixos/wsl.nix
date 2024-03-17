{config, lib, origin, ...}: with lib; let
  defaultUser = config.copper.feature.default-user.user;
in {
  imports = [
    origin.inputs.nixos-wsl.nixosModules.default
  ];

  wsl.enable = true;
  wsl.defaultUser = mkDefault defaultUser;

  copper.feature.home-manager.enable = true;

  home-manager.users.${defaultUser} = {
    copper.features = [
      "wsl"
    ];
  };
}