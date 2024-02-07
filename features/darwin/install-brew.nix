{
  config,
  lib,
  origin,
  ...
}: {
  imports = [
    origin.inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  nix-homebrew.enable = true;
  nix-homebrew.patchBrew = false;
  nix-homebrew.user = config.defaultUser;

  environment.extraInit = ''eval "$(brew shellenv)"'';

  # Workaround for nix-homebrew#3
  # TODO: remove once the issue above is fixed
  system.activationScripts.extraUserActivation.text = lib.mkOrder 1501 (lib.concatStringsSep "\n" (lib.mapAttrsToList (prefix: d:
    if d.enable
    then ''
      sudo chown -R ${config.nix-homebrew.user} ${prefix}/bin
      sudo chgrp -R ${config.nix-homebrew.group} ${prefix}/bin
    ''
    else "")
  config.nix-homebrew.prefixes));
}
