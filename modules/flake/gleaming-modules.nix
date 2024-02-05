gg: {config, lib, flake-parts-lib, ...}: {
  options = with lib; {
    flake = flake-parts-lib.mkSubmoduleOptions {
      # flake-parts only has built-in definitions for nixosModules, which is
      # typically fine, since the Flake output allows for arbitrary outputs.
      # However, without a type definition, attribute sets cannot be merged,
      # so this module causes a conflict. Thus, we need to tell flake-parts
      # that homeModules and darwinModules are also simple attrsets.
      homeModules = mkOption {
        type = types.lazyAttrsOf types.unspecified;
        description = ''
          Home-Manager modules.

          These are used for re-usable parts of Home-Manager configurations.
        '';
      };
      darwinModules = mkOption {
        type = types.lazyAttrsOf types.unspecified;
        description = ''
          nix-darwin modules.

          These are used for re-usable parts of nix-darwin configurations.
        '';
      }; 
    };
  };

  config = {
    flake = let
      load = kind: lib.mapAttrs' (name: lib.nameValuePair "${config.gleaming.basename}-${name}") (gg.lib.loadModules {inherit (config) gleaming;} config.gleaming.basename ../../gleaming kind);
    in {
      nixosModules = load "nixos";
      homeModules = load "home-manager";
      darwinModules = load "darwin";
    };
  };
}