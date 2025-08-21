{origin, ...}: {
  config = {
    perSystem = {system, ...}: {
      # TODO: this probably causes a conflict with my root flake
      apps = { inherit (origin.apps.${system}) generate bootstrap set-hostname; };
    };
  };
}