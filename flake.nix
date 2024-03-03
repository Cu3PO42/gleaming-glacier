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

    # The Window Manager I use + tooling
    hyprlang = {
      url = "github:hyprwm/hyprlang";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems-linux";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems-linux";
      inputs.hyprlang.follows = "hyprlang";
    };

    hypridle = {
      url = "github:hyprwm/hypridle";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems-linux";
      inputs.hyprlang.follows = "hyprlang";
    };

    hyprlock = {
      url = "github:hyprwm/hyprlock";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems-linux";
      inputs.hyprlang.follows = "hyprlang";
    };

    hypr-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
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

    # Loading of 'normal' binaries
    nix-ld-rs = {
      url = "github:nix-community/nix-ld-rs";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-compat.follows = "flake-compat";
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

    # To create re-usable Flake logic
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };

    # Only for deduplication of other transitive dependencies
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

    systems-linux = {
      url = "github:nix-systems/default-linux";
    };
  };

  outputs = inputs: let
    lib = import ./lib inputs;
  in lib.mkGleamingFlake inputs ./. "copper" (flakeModules: {
    imports = [
      # Allow unfree packages; required because some of our own packages have
      # unfree dependencies.
      flakeModules.allow-unfree
    ];

    # We don't want to inherit our own modules!
    copper.inheritModules = false;

    perSystem = {system, pkgs, ...}: {
      devShells = {
        # Shell for bootstrapping either a NixOS or Home-Manager config
        default = import ./shell.nix {inherit pkgs;};
      };
    };
  });
}
