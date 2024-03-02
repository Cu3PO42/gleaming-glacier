{flake-parts, ...}@lib-inputs: {
  mkGleamingFlake = inputs: src: namespace: module: let
    inherit (import ./loading.nix lib-inputs) loadDirRec;
    inherit (import ./modules.nix lib-inputs) importInjectArgs;
  
    copperModules = loadDirRec ../modules/flake ({path, ...}: importInjectArgs { origin = lib-inputs.self.outputs // { inputs = lib-inputs; }; } path);

  in flake-parts.lib.mkFlake {inherit inputs;} ({ self, inputs, ... }: let
      flakeModules = loadDirRec (src + "/modules/flake") ({path, ...}: importInjectArgs { origin = self // { inherit inputs; }; } path);
    in {
      imports = [
        (module flakeModules)
        copperModules.base
        copperModules.autoload
        copperModules.copper-config
        copperModules.copper-chroma
        copperModules.copper-mage
        copperModules.copper-plate
        copperModules.default-overlays
        copperModules.gleaming
        copperModules.gleaming-modules
        copperModules.inherit-copper
      ];

      gleaming = {
        inherit src namespace;
      };

      flake = {
        inherit flakeModules;
      };
    }
  );
}