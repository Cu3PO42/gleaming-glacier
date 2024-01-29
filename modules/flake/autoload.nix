{config, lib, inputs, self, ...}: with lib; let
  cfg = config.copper.autoload;

  loadApps = base: pkgs: self.lib.loadDir (base + "/apps") ({path, ...}: {
    type = "app";
    program = pkgs.lib.getExe (pkgs.callPackage path {inherit inputs;});
  });

  loadPackages = base: pkgs: lib.filterAttrs (_: pkgs.lib.meta.availableOn pkgs.hostPlatform) (
    self.lib.loadDir (base + "/packages") ({path, ...}: pkgs.callPackage path {inherit inputs;})
  );
in {
  options = {
    copper.autoload.base = mkOption {
      type = types.path;
      example = literalExpression "./.";
      description = "The base path of the Flake from which to load all elmements.";
    };
  };

  config = {
    perSystem = {pkgs, ...}: {
      apps = loadApps cfg.base pkgs;

      packages = loadPackages cfg.base pkgs;
    };
  };
}