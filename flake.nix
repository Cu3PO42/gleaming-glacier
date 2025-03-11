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
      inputs.nix-filter.follows = "nix-filter";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.systems.follows = "systems";
    };

    # NixOS inputs
    # Secure Boot
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.pre-commit-hooks-nix.follows = "pre-commit-hooks";
      inputs.flake-parts.follows = "flake-parts";
      inputs.flake-compat.follows = "flake-compat";
      inputs.rust-overlay.follows = "rust-overlay";
    };

    # NixOS on WSL - Duh.
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };

    # UI Tooling
    gtk-session-lock = {
      url = "github:Cu3PO42/gtk-session-lock";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ags = {
      url = "github:Cu3PO42/ags/new-polkit";
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

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };

    nix-filter = {
      url = "github:numtide/nix-filter";
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

  nixConfig = {
    extra-substituters = [
      "https://cache.garnix.io"
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
    ];

    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };
}
