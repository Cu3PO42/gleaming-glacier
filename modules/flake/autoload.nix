{config, lib, inputs, self, ...}: with lib; let
  cfg = config.copper.autoload;

  loadApps = base: pkgs: self.lib.loadDir (base + "/apps") ({path, ...}: {
    type = "app";
    program = pkgs.lib.getExe (pkgs.callPackage path {inherit inputs;});
  });

  loadPackages = base: pkgs: lib.filterAttrs (_: pkgs.lib.meta.availableOn pkgs.hostPlatform) (
    self.lib.loadDir (base + "/packages") ({path, ...}: pkgs.callPackage path {inherit inputs;})
  );

  specialArgs = {
    inherit inputs;
    inherit (inputs.self) outputs;
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
      # TODO: find a way to get rid of manual specialArgs_ passing; probably using something from flake-parts
      nixosModules = self.lib.loadModules specialArgs cfg.base "nixos";
      homeModules = self.lib.loadModules specialArgs cfg.base "home-manager";
      darwinModules = self.lib.loadModules specialArgs cfg.base "darwin";
    };

    perSystem = {pkgs, ...}: {
      apps = loadApps cfg.base pkgs;

      packages = loadPackages cfg.base pkgs;
    };
  };
}