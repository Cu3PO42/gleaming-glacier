{config, lib, inputs, self, ...}: with lib; let
  cfg = config.copper.autoload;

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
  options = {
    copper.autoload.base = mkOption {
      type = types.path;
      example = literalExpression "./.";
      description = "The base path of the Flake from which to load all elmements.";
    };
  };

  config = {
    flake = {
      templates = import (cfg.base + "/templates");

      # TODO: find a way to get rid of manual specialArgs_ passing; probably using something from flake-parts
      nixosModules = self.lib.loadModules specialArgs cfg.base "nixos";
      homeModules = self.lib.loadModules specialArgs cfg.base "home-manager";
      darwinModules = self.lib.loadModules specialArgs cfg.base "darwin";

      nixosConfigurations = loadNixos {dir = cfg.base + "/hosts/nixos";};
      homeConfigurations = loadHome {dir = cfg.base + "/users";};
      darwinConfigurations = loadDarwin {dir = cfg.base + "/hosts/darwin";};
    };

    perSystem = {pkgs, system, config, inputs', ...}: let
      extraPkgArgs = {
        self = config.packages // config.legacyPackages;
        inputs = inputs';
      };
    in {
      apps = loadApps cfg.base pkgs;

      packages = loadPackages lib system (cfg.base + "/packages") pkgs extraPkgArgs;
      legacyPackages = loadPackages lib system (cfg.base + "/legacy-packages") pkgs extraPkgArgs;

      chromaThemes = mkIf (options ? perSystem.chromaThemes) import (cfg.base + "/themes") {inherit pkgs;};
    };
  };
}