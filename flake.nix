{
  description = "Copper's NixOS and Home Manager configurations";

  inputs = {
    # Common Inputs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-search-cli = {
      url = "github:peterldowns/nix-search-cli";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-utils.follows = "flake-utils";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # NixOS inputs
    # Secure Boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-parts.follows = "flake-parts";
      inputs.flake-compat.follows = "flake-compat";
      inputs.flake-utils.follows = "flake-utils";
    };

    # The Window Manager I use
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    # Support for erasing / on every boot
    impermanence.url = "github:nix-community/impermanence";

    # Declerative disk formatting
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS installation on running servers
    nixos-anywhere = {
      url = "github:numtide/nixos-anywhere";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.disko.follows = "disko";
      inputs.flake-parts.follows = "flake-parts";
    };

    # Provides a pre-built index database describing which binaries are
    # available in which packages
    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Darwin Inputs
    nix-darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Install Homebrew via Nix
    nix-homebrew = {
      url = "github:zhaofengli/nix-homebrew";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.nix-darwin.follows = "nix-darwin";
    };

    # Only for deduplication of other transitive dependencies
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };

    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };

    systems = {
      url = "github:nix-systems/default";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nix-darwin,
    ...
  } @ inputs: let
    lib = import ./lib inputs;
    inherit (lib) loadDir loadDirRec mkFeatureModule injectArgs;

    forAllSystems = f:
      nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"] (s:
        f (import nixpkgs {
          system = s;
          config.allowUnfree = true;
        }));

    specialArgs = {
      inherit inputs;
      inherit (self) outputs;
    };

    loadModules = base: name:
      nixpkgs.lib.mapAttrs (_: injectArgs specialArgs) (
        loadDirRec (base + "/modules/common") ({path, ...}: import path)
        // loadDirRec (base + "/modules/${name}") ({path, ...}: import path)
        # TODO: consider moving this to modules/feature subdirectory;
        // nixpkgs.lib.mapAttrs' (name: value: {
          name = "feature/${name}";
          inherit value;
        }) (loadDirRec (base + "/features/${name}") (
          {
            name,
            path,
            ...
          }:
            mkFeatureModule {
              name = builtins.replaceStrings ["/"] ["."] name;
              cfg = import path;
            }
        ))
      );

    loadSystems = {
      constructor,
      copperModules,
    }: {
      dir,
      extraModules ? [],
      withCopperModules ? true,
    }:
      loadDir dir ({
        path,
        name,
        ...
      }: let
        modules =
          [
            (import path)
            ({lib, ...}: {
              networking.hostName = lib.mkOverride 999 (lib.removeSuffix ".nix" name);
            })
          ]
          ++ nixpkgs.lib.optionals withCopperModules (copperModules
            ++ [
              ({lib, ...}: {
                copper.feature.base.enable = lib.mkDefault true;
              })
            ])
          ++ extraModules;
      in
        constructor {
          inherit modules specialArgs;
        });
    loadNixos = loadSystems {
      constructor = nixpkgs.lib.nixosSystem;
      copperModules = nixpkgs.lib.attrValues self.outputs.nixosModules;
    };
    loadDarwin = loadSystems {
      constructor = nix-darwin.lib.darwinSystem;
      copperModules = nixpkgs.lib.attrValues self.outputs.darwinModules;
    };

    loadHome = {
      dir,
      extraModules ? [],
      withCopperModules ? true,
    }:
      loadDir dir ({
        path,
        name,
        ...
      }: let
        user = import path;
        username = builtins.elemAt (nixpkgs.lib.splitString "@" name) 0;
        modules =
          (nixpkgs.lib.optionals withCopperModules (nixpkgs.lib.attrValues self.outputs.homeModules
            ++ [
              ({lib, ...}: {
                copper.feature.standaloneBase.enable = lib.mkDefault true;
              })
            ]))
          ++ extraModules
          ++ [
            ({lib, ...}: {
              home.username = lib.mkDefault username;
            })
          ]
          ++ user.modules or [];
      in
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${user.system};
          inherit modules;
          extraSpecialArgs = specialArgs;
        });
  in {
    lib =
      lib
      // {
        # TODO: move these defintions from flake.nix into a lib file
        inherit loadNixos loadHome loadDarwin loadModules;
      };

    # Shell for bootstrapping either a NixOS or Home-Manager config
    devShells = forAllSystems (pkgs: import ./shell.nix {inherit pkgs;});

    # Required to make nix fmt work
    formatter = forAllSystems (pkgs: pkgs.alejandra);

    apps = forAllSystems (pkgs: import ./apps (inputs // {inherit pkgs;}));
    packages = forAllSystems (pkgs: pkgs.lib.filterAttrs (n: v: v != null) (import ./packages (inputs // {inherit pkgs;})));

    overlays = import ./overlays {
      inherit inputs;
      inherit (self) outputs;
    };

    templates = import ./templates;

    nixosModules = loadModules ./. "nixos";
    homeModules = loadModules ./. "home-manager";
    darwinModules = loadModules ./. "darwin";

    nixosConfigurations = loadNixos {dir = ./hosts/nixos;};
    homeConfigurations = loadHome {dir = ./users;};
    darwinConfigurations = loadDarwin {dir = ./hosts/darwin;};
  };
}
