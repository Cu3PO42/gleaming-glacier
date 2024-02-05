{flake-parts, ...}@lib-inputs: {
  mkGleamingFlake = inputs: base: module: let
    inherit (import ./loading.nix lib-inputs) loadDirRec;
  
    copperModules = loadDirRec ../modules/flake ({path, ...}: flake-parts.lib.importApply path lib-inputs.self.outputs);

  in flake-parts.lib.mkFlake {inherit inputs;} (args: let
      flakeModules = loadDirRec (base + "/modules/flake") ({path, ...}: flake-parts.lib.importApply path args.self);
    in {
      imports = [
        (module flakeModules)
        copperModules.base
        copperModules.autoload
        copperModules.copper-chroma
        copperModules.default-overlays
        copperModules.gleaming
        copperModules.gleaming-modules
      ];

      gleaming.basepath = base;

      flake = {
        inherit flakeModules;
      };
    }
  );
}