# Exposed as tests.loading and run by nix-unit through nix flake check.
{lib}: let
  loader = import ../lib/loading.nix {
    nixpkgs = {
      inherit lib;
      legacyPackages.test = {};
    };
    home-manager.lib.homeManagerConfiguration = args:
      builtins.seq args.pkgs { selected = true; };
  };
  fixtures = ./loading/modules/fixtures;
  flatNames = ["broken" "good" "nested" "recursive"];
  recursiveNames = ["broken" "good" "nested" "recursive/deep"];
  args = { modules = []; specialArgs = {}; dir = fixtures; };
  # Force the selected entry's module, so selecting a broken fixture fails.
  systems = loader.loadSystems (args:
    builtins.deepSeq (builtins.head args.modules) { selected = true; }) args;
  homes = loader.loadHome args;
  packages = loader.loadPackages' fixtures { callPackage = path: _: import path; } {};
  modules = loader.loadModules {
    injectionArgs = {};
    namespace = "test";
    src = ./loading;
  } "fixtures";
in {
  testFlatDiscovery = {
    expr = builtins.attrNames (loader.loadDir fixtures (_: throw "callback forced"));
    expected = flatNames;
  };
  testRecursiveDiscovery = {
    expr = builtins.attrNames (loader.loadDirRec fixtures (_: throw "callback forced"));
    expected = recursiveNames;
  };
  testFlatSelection = {
    expr = (loader.loadDir fixtures ({path, ...}: import path)).good.main.selected;
    expected = true;
  };
  testRecursiveSelection = {
    expr = (loader.loadDirRec fixtures ({path, ...}: import path)).good.main.selected;
    expected = true;
  };
  testFlatNullRetained = {
    expr = (loader.loadDir fixtures (_: null)).good;
    expected = null;
  };
  testRecursiveNullRetained = {
    expr = (loader.loadDirRec fixtures (_: null)).good;
    expected = null;
  };
  testMissingFlatDirectory = {
    expr = loader.loadDir (fixtures + "/missing") (_: throw "callback forced");
    expected = {};
  };
  testMissingRecursiveDirectory = {
    expr = loader.loadDirRec (fixtures + "/missing") (_: throw "callback forced");
    expected = {};
  };
  testSystemDiscovery = { expr = builtins.attrNames systems; expected = flatNames; };
  testSystemSelection = { expr = systems.good.selected; expected = true; };
  testHomeDiscovery = { expr = builtins.attrNames homes; expected = flatNames; };
  testHomeSelection = { expr = homes.good.selected; expected = true; };
  testPackageDiscovery = { expr = builtins.attrNames packages; expected = flatNames; };
  testPackageSelection = { expr = packages.good.main.selected; expected = true; };
  testModuleDiscovery = { expr = builtins.attrNames modules; expected = recursiveNames; };
  testSelectedErrorPreserved = {
    expr = (builtins.tryEval systems.broken).success;
    expected = false;
  };
}
