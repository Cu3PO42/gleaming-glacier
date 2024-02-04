{config, lib, inputs, self, ...}@moduleArgs: with lib; let
  base = config.gleaming.basepath;

  # TODO: maybe find a way to add these to lib
  loadApps = base: pkgs: self.lib.loadDir (base + "/apps") ({path, ...}: {
    type = "app";
    program = pkgs.lib.getExe (pkgs.callPackage path {inherit inputs;});
  });

  specialArgs = {
    inherit inputs;
    inherit (inputs.self) outputs;
  };

  inherit (self.lib) loadSystems loadPackages;

  # TODO: probably also move these to lib
  loadNixos = loadSystems {
    specialArgs_ = specialArgs;
    constructor = inputs.nixpkgs.lib.nixosSystem;
    copperModules = lib.attrValues self.outputs.nixosModules;
  };

  loadDarwin = loadSystems {
    specialArgs_ = specialArgs;
    constructor = inputs.nix-darwin.lib.darwinSystem;
    copperModules = lib.attrValues self.outputs.darwinModules;
  };

  loadHome = self.lib.loadHome {
    specialArgs_ = specialArgs;
    copperModules = lib.attrValues self.outputs.homeModules;
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
      nixosModules = self.lib.loadModules specialArgs config.gleaming.basename base "nixos";
      homeModules = self.lib.loadModules specialArgs config.gleaming.basename base "home-manager";
      darwinModules = self.lib.loadModules specialArgs config.gleaming.basename base "darwin";

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