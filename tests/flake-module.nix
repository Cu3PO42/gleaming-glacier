{inputs, ...}: {
  imports = [inputs.nix-unit.modules.flake.default];

  flake.tests.loading = import ./loading.nix {inherit (inputs.nixpkgs) lib;};
  flake.tests.ci = import ./ci.nix {inherit (inputs.nixpkgs) lib;};

  perSystem = {pkgs, config, ...}: {
    checks.ci-helpers = pkgs.callPackage ./ci-helpers.nix {};
    checks.mage = config.packages.mage.tests.integration;

    nix-unit = {
      package = pkgs.nix-unit;
      inputs = {
        inherit (inputs) nixpkgs flake-parts nix-unit;
        "flake-parts/nixpkgs-lib" = inputs.flake-parts.inputs.nixpkgs-lib;
      };
    };
  };
}
