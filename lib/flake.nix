{flake-parts, ...}@lib-inputs: {
  mkGleamingFlake = inputs: base: module: let
    inherit (import ./loading.nix lib-inputs) loadDirRec;
  
    copperModules = loadDirRec ../modules/flake ({path, ...}: import path);

    flakeModules = loadDirRec (base + "/modules/flake") ({path, ...}: import path);
  in flake-parts.lib.mkFlake {inherit inputs;} {
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
  };
}