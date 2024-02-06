gg: {config, lib, inputs, ...}@moduleArgs: with lib; let
  base = config.gleaming.basepath;
  cfg = config.gleaming.autoload;

  inherit (gg.lib) loadSystems loadHome loadPackages loadApps loadModules;

  loadNixos = loadSystems inputs.nixpkgs.lib.nixosSystem;
  loadDarwin = loadSystems inputs.nix-darwin.lib.darwinSystem;

  loadModules' = loadModules {
    inherit (config.gleaming) basename basepath;
    injectionArgs = cfg.moduleInjectionArgs;
  };
in {
  options = {
    gleaming.autoload = {
      baseModules = let
        mkModuleOption = name: mkOption {
          type = with types; listOf unspecified;
          default = [];
          description = ''
            List of modules to include in any ${name} configuration created by the
            autoload Flake module.
          '';
        };
      in {
        nixos = mkModuleOption "NixOS";
        home = mkModuleOption "Home-Manager";
        darwin = mkModuleOption "nix-darwin";
      };

      moduleInjectionArgs = mkOption {
        type = with types; attrsOf unspecified;
        default = {};
        example = lib.literalExpression ''{ origin = self; }'';
        description = ''
          Additional arguments that should be passed to the modules loaded by
          the autoload module. They are injected at load time and not via the
          including configurations's `specialArgs` or `extraSpecialArgs`.

          This makes them especially useful to passing in arguments from your
          own Flake, rather than requiring all users of the module to pass them
          via `specialArgs`.
        '';
      };

      specialArgs = mkOption {
        type = with types; attrsOf unspecified;
        default = {};
        description = ''
          Additional arguments that should be passed to any
          NixOS/nix-darwin/Home-Manager configurations via their specialArgs.
        '';
      };
    };
  };

  config = {
    gleaming.autoload = rec {
      baseModules = {
        nixos = lib.attrValues config.flake.nixosModules;
        home = lib.attrValues config.flake.homeModules;
        darwin = lib.attrValues config.flake.darwinModules;
      };

      moduleInjectionArgs = {
        inputs = inputs;
        outputs = inputs.self.outputs;
      };

      specialArgs = moduleInjectionArgs;
    };

    flake = {
      lib = import (base + "/lib") inputs;

      templates = import (base + "/templates");
      overlays = import (base + "/overlays") moduleArgs;

      nixosModules = loadModules' "nixos";
      homeModules = loadModules' "home-manager";
      darwinModules = loadModules' "darwin";

      nixosConfigurations = loadNixos {
        specialArgs = cfg.specialArgs // {
          hmSpecialArgs = cfg.specialArgs;
          hmBaseModules = cfg.baseModules.home;
        };
        modules = config.gleaming.autoload.baseModules.nixos;
        dir = base + "/hosts/nixos";
      };
      homeConfigurations = loadHome {
        inherit (cfg) specialArgs;
        modules = config.gleaming.autoload.baseModules.home;
        dir = base + "/users";
      };
      darwinConfigurations = loadDarwin {
        inherit (cfg) specialArgs;
        modules = config.gleaming.autoload.baseModules.darwin;
        dir = base + "/hosts/darwin";
      };
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