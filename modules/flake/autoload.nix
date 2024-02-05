gg: {config, lib, inputs, ...}@moduleArgs: with lib; let
  base = config.gleaming.basepath;

  # TODO: maybe find a way to add these to lib
  loadApps = base: pkgs: gg.lib.loadDir (base + "/apps") ({path, ...}: {
    type = "app";
    program = pkgs.lib.getExe (pkgs.callPackage path {inherit inputs;});
  });

  specialArgs = {
    inherit inputs;
    inherit (inputs.self) outputs;
  };

  inherit (gg.lib) loadSystems loadPackages;

  # TODO: probably also move these to lib
  loadNixos = loadSystems {
    specialArgs_ = specialArgs;
    constructor = inputs.nixpkgs.lib.nixosSystem;
    copperModules = lib.attrValues gg.nixosModules;
  };

  loadDarwin = loadSystems {
    specialArgs_ = specialArgs;
    constructor = inputs.nix-darwin.lib.darwinSystem;
    copperModules = lib.attrValues gg.darwinModules;
  };

  loadHome = gg.lib.loadHome {
    specialArgs_ = specialArgs;
    copperModules = lib.attrValues gg.homeModules;
  };
in {
  options = {};

  config = {
    flake = {
      # FIXME: readd loadNixos, loadDarwin to export?
      lib = import (base + "/lib") inputs;

      templates = import (base + "/templates");
      overlays = import (base + "/overlays") moduleArgs;

      # TODO: find a way to get rid of manual specialArgs_ passing; probably using something from flake-parts
      nixosModules = gg.lib.loadModules specialArgs config.gleaming.basename base "nixos";
      homeModules = gg.lib.loadModules specialArgs config.gleaming.basename base "home-manager";
      darwinModules = gg.lib.loadModules specialArgs config.gleaming.basename base "darwin";

      nixosConfigurations = loadNixos {dir = base + "/hosts/nixos";};
      homeConfigurations = loadHome {dir = base + "/users";};
      darwinConfigurations = loadDarwin {dir = base + "/hosts/darwin";};
    };

    perSystem = {pkgs, system, config, options, inputs', ...}: let
      extraPkgArgs = {
        self = config.packages // config.legacyPackages;
        inputs = inputs';
      };
    in {
      apps = loadApps base pkgs;

      packages = loadPackages lib system (base + "/packages") pkgs extraPkgArgs;
      legacyPackages = loadPackages lib system (base + "/legacy-packages") pkgs extraPkgArgs;

      chromaThemes = mkIf (options ? chromaThemes) (import (base + "/themes") {inherit pkgs;extraArgs = extraPkgArgs;});
    };
  };
}