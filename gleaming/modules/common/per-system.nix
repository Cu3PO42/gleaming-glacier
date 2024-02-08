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
      system = origin.getSystemIgnoreWarning (pkgs.stdenv.hostPlatform.system or pkgs.system);
      # This is included via flake-parts' withSystem
      systemWithOurPkgs = sys.allModuleArgs.extendModules ({
        modules = [{
          _module.args.pkgs = lib.mkForce pkgs;
        }];
      }).config;
      selectedSystem = if config.${gleaming.basename}.perSystem.useConfigPkgs
        then systemWithOurPkgs
        else system;
    in selectedSystem // { inherit (selectedSystem.allModuleArgs) inputs'; };
  };
}