{
  lib,
  systems,
  flake,
  exclude ? [],
}: let
  # Match complete output paths; * stands for exactly one attribute component.
  matches = path: pattern: let
    parts = lib.splitString "." pattern;
  in
    builtins.length path
    == builtins.length parts
    && lib.all (pair: pair.fst == "*" || pair.fst == pair.snd) (lib.zipLists parts path);

  # Filter by name before selecting build outputs, so excluded configurations
  # can contain evaluation errors without breaking the matrix.
  select = prefix: lib.filterAttrs (name: _: !lib.any (matches (prefix ++ [name])) exclude);
  perSystem = kind:
    lib.genAttrs systems (system:
      # Inspect metadata only after name exclusions, and before forcing drvPath.
      lib.filterAttrs (_: drv: !(drv.meta.broken or false))
      (select [kind system] (flake.${kind}.${system} or {})));
  configurations = kind: build:
    lib.filterAttrs (_: drv: builtins.elem drv.system systems)
    (lib.mapAttrs (_: build) (select [kind] (flake.${kind} or {})));
in {
  packages = perSystem "packages";
  checks = perSystem "checks";
  homeConfigurations = configurations "homeConfigurations" (home: home.activationPackage);
  nixosConfigurations = configurations "nixosConfigurations" (host: host.config.system.build.toplevel);
  darwinConfigurations = configurations "darwinConfigurations" (host: host.system);
}
