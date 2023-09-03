{
  inputs = {
    # Use the latest nixpkgs.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Reference Copper's dotfiles for configuration re-use
    copper.url = "github:Cu3PO42/gleaming-glacier";
    # Replace the upstream's nixpkgs with our own, so we don't unnecessarily
    # duplicate dependencies.
    copper.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    copper,
    ...
  } @ inputs:
    with copper.lib; let
      # This is a simple helper function that for a given function f, runs
      # `f sysetm` for any system in the list and stores the result in an
      # attribute called `system`.
      # This is used to abstract over systems for all attrtibutes that support
      # multiple.
      forAllSystems = nixpkgs.lib.genAttrs ["x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin"];
    in {
      # Copy the formatter, this is required so that `nix fmt` works.
      inherit (copper) formatter;

      # Copy the plate tool, which we might need to deploy a server.
      packages = forAllSystems (s: {inherit (copper.packages.${s}) plate;});
      # Copy the scripts that simplify usage of this template.
      apps = forAllSystems (s: {inherit (copper.apps.${s}) generate bootstrap;});
      # Copy the devShell that can be used for initial setup
      devShells = forAllSystems (s: {inherit (copper.devShells) default;});

      # Just as in Copper's flake, load all modules from their respective folders.
      # This implicilty imports all .nix files in the module folders!
      nixosModules = loadModules ./. "nixos";
      homeModules = loadModules ./. "home-manager";
      darwinModules = loadModules ./. "darwin";

      # Just as in Copper's flake, load all host and user configurations from
      # their respective folders. Additionally, pass in any modules defined in
      # this flake. Modules from Copper's flake are also included. Pass
      # `withCopperModules = false` to change that behavior.
      nixosConfigurations = loadNixos {
        dir = ./hosts/nixos;
        extraModules = builtins.attrValues self.outputs.nixosModules;
      };
      homeConfigurations = loadHome {
        dir = ./users;
        extraModules = builtins.attrValues self.outputs.homeModules;
      };
      darwinConfigurations = loadDarwin {
        dir = ./hosts/darwin;
        extraModules = builtins.attrValues self.outputs.darwinModules;
      };
    };
}
