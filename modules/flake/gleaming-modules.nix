{config, options, lib, flake-parts-lib, origin, specialArgs, ...}@args: {
  options = with lib; {
    flake = flake-parts-lib.mkSubmoduleOptions {
      # flake-parts only has built-in definitions for nixosModules, which is
      # typically fine, since the Flake output allows for arbitrary outputs.
      # However, without a type definition, attribute sets cannot be merged,
      # so this module causes a conflict. Thus, we need to tell flake-parts
      # that homeManagerModules and darwinModules are also simple attrsets.
      homeManagerModules = mkOption {
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
      loadModules' = kind: lib.mapAttrs' (name: lib.nameValuePair "${config.gleaming.namespace}-${name}") (origin.lib.loadModules {
        inherit (config.gleaming) namespace;
        src = ../../gleaming;
        injectionArgs = { origin = config._module.args // specialArgs // { inherit config options; }; };
      } kind);
    in {
      nixosModules = loadModules' "nixos";
      homeManagerModules = loadModules' "home-manager";
      darwinModules = loadModules' "darwin";
    };
  };
}