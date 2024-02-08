{config, lib, pkgs, origin, ...}: with lib; let
  inherit (origin.config) gleaming;
in {
  options = {
    ${gleaming.basename}.perSystem.useConfigPkgs = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Use the nixpkgs instance from the configuration instead of the one
        provided by the flake. This is useful if you want to use overlays to
        patch issues, for example. Note that this requires your nixpkgs setup
        to be compatible with what the flake expects. It also requires another
        evaluation of packages and is not generally recommended.
      '';
    };
  };

  config = {
    _module.args.${gleaming.basename} = let
      system = pkgs.stdenv.hostPlatform.system or pkgs.system;
      perSystem = origin.getSystemIgnoreWarning (system);
      # This is included via flake-parts' withSystem
      perSystemWithOurPkgs = sys.allModuleArgs.extendModules ({
        modules = [{
          _module.args.pkgs = lib.mkForce pkgs;
        }];
      }).config;
      selectedPerSystem = if config.${gleaming.basename}.perSystem.useConfigPkgs
        then perSystemWithOurPkgs
        else perSystem;
      inputs = mapAttrs (_: e:
        let
          select = e: prop: (e.${prop} or {}).${system} or {};
          pkgs = select e "legacyPackages" // select e "packages";
        in if pkgs ? default then pkgs.default // pkgs else pkgs
      ) origin.inputs;
    in selectedPerSystem // { inherit inputs; };
  };
}