{lib}: let
  systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
  drv = system: name: {
    type = "derivation";
    inherit system name;
    drvPath = "/nix/store/${name}.drv";
  };
  linux = drv "x86_64-linux" "linux";
  arm = drv "aarch64-linux" "arm";
  darwin = drv "aarch64-darwin" "darwin";
  unsupported = drv "x86_64-darwin" "unsupported";
  broken = linux // {
    meta.broken = true;
    drvPath = throw "broken derivation forced";
  };
  jobs = import ../ci {
    inherit lib systems;
    exclude = [
      "packages.*.excluded"
      "checks.x86_64-linux.excluded"
      "homeConfigurations.excluded"
      "nixosConfigurations.excluded"
      "darwinConfigurations.excluded"
    ];
    flake = {
      packages = {
        x86_64-linux = {
          keep = linux;
          inherit broken;
          healthy = linux // {meta.broken = false;};
          excluded = throw "excluded package forced";
        };
        aarch64-linux = {
          keep = arm;
          excluded = throw "excluded ARM package forced";
        };
        aarch64-darwin.keep = darwin;
        x86_64-darwin.ignored = throw "unsupported package set forced";
      };
      checks.x86_64-linux = {
        keep = linux;
        inherit broken;
        excluded = throw "excluded check forced";
      };
      homeConfigurations = {
        linux.activationPackage = linux;
        darwin.activationPackage = darwin;
        unsupported.activationPackage = unsupported;
        excluded = throw "excluded home forced";
      };
      nixosConfigurations = {
        linux.config.system.build.toplevel = linux;
        arm.config.system.build.toplevel = arm;
        excluded = throw "excluded NixOS host forced";
      };
      darwinConfigurations = {
        darwin.system = darwin;
        excluded = throw "excluded Darwin host forced";
      };
    };
  };
  empty = import ../ci {
    inherit lib systems;
    flake = {};
  };
in {
  testPackageSystems = {
    expr = builtins.attrNames jobs.packages;
    expected = builtins.sort builtins.lessThan systems;
  };
  testPackageWildcardExclusions = {
    expr = lib.mapAttrs (_: builtins.attrNames) jobs.packages;
    expected = (lib.genAttrs systems (_: ["keep"])) // {
      x86_64-linux = ["healthy" "keep"];
    };
  };
  testCheckExclusions = {
    expr = builtins.attrNames jobs.checks.x86_64-linux;
    expected = ["keep"];
  };
  testUnmodifiedPackage = {
    expr = jobs.packages.x86_64-linux.keep;
    expected = linux;
  };
  testHomePlatformsAndExclusions = {
    expr = jobs.homeConfigurations;
    expected = {inherit linux darwin;};
  };
  testNixosPlatformsAndExclusions = {
    expr = jobs.nixosConfigurations;
    expected = {inherit linux arm;};
  };
  testDarwinPlatformAndExclusions = {
    expr = jobs.darwinConfigurations;
    expected = {inherit darwin;};
  };
  testMissingOutputs = {
    expr = empty;
    expected = {
      packages = lib.genAttrs systems (_: {});
      checks = lib.genAttrs systems (_: {});
      homeConfigurations = {};
      nixosConfigurations = {};
      darwinConfigurations = {};
    };
  };
}
