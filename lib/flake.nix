{flake-parts, ...}@lib-inputs: {
  mkGleamingFlake = inputs: base: module: let
    inherit (import ./loading.nix lib-inputs) loadDirRec;
    inherit (import ./modules.nix lib-inputs) importInjectArgs;
  
    copperModules = loadDirRec ../modules/flake ({path, ...}: importInjectArgs { origin = lib-inputs.self.outputs; } path);

  in flake-parts.lib.mkFlake {inherit inputs;} (args: let
      flakeModules = loadDirRec (base + "/modules/flake") ({path, ...}: importInjectArgs { origin = args.self; } path);
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

      gleaming.basepath = base;

      flake = {
        inherit flakeModules;
      };
    }
  );
}