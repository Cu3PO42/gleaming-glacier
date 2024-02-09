{flake-parts, ...}@lib-inputs: {
  mkGleamingFlake = inputs: basepath: basename: module: let
    inherit (import ./loading.nix lib-inputs) loadDirRec;
    inherit (import ./modules.nix lib-inputs) importInjectArgs;
  
    copperModules = loadDirRec ../modules/flake ({path, ...}: importInjectArgs { origin = lib-inputs.self.outputs // { inputs = lib-inputs; }; } path);

  in flake-parts.lib.mkFlake {inherit inputs;} ({ self, inputs, ... }: let
      flakeModules = loadDirRec (basepath + "/modules/flake") ({path, ...}: importInjectArgs { origin = self // { inherit inputs; }; } path);
    in {
      imports = [
        (module flakeModules)
        copperModules.base
        copperModules.autoload
        copperModules.copper-chroma
        copperModules.default-overlays
        copperModules.gleaming
        copperModules.gleaming-modules
        copperModules.inherit-copper
      ];

      gleaming = {
        inherit basepath basename;
      };

      flake = {
        inherit flakeModules;
      };
    }
  );
}