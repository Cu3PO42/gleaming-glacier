{config, lib, flake-parts-lib, origin, getSystemIgnoreWarning, ...}@args: {
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
      loadModules' = kind: lib.mapAttrs' (name: lib.nameValuePair "${config.gleaming.basename}-${name}") (origin.lib.loadModules {
        inherit (config.gleaming) basename;
        basepath = ../../gleaming;
        # FIXME: we need to implement this similar to how moduleWithSystem does it; this way we only have what is specified above
        injectionArgs = { origin = args; };
      } kind);
    in {
      nixosModules = loadModules' "nixos";
      homeModules = loadModules' "home-manager";
      darwinModules = loadModules' "darwin";
    };
  };
}