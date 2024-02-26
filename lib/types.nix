{nixpkgs, ...}: with nixpkgs.lib; rec {
  colorType = types.str // {
    check = s: types.str.check s && (builtins.match "^[0-9a-fA-F]{6}$" s != null);
  };

  # Behaves just like types.submodule but allows for assertions to be addded.
  submoduleWithAssertions = module: let
    base = types.submoduleWith {
      modules = [module (import "${nixpkgs}/nixos/modules/misc/assertions.nix")];
      shorthandOnlyDefinesConfig = true;
    };

  in base // {
    merge = loc: defs: let
      config = base.merge loc defs;
      # Adapted from nixpkgs/nixos/modules/system/activation/top-level.nix
      failedAssertions = map (x: x.message) (filter (x: !x.assertion) config.assertions);

      configAssertWarn = if failedAssertions != []
        then throw "\nFailed assertions:\n${concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}"
        else showWarnings config.warnings config;
    in configAssertWarn;

    getSubModules = [module];
    substSubModules = m: submoduleWithAssertions { imports = m; }; 
    functor = types.defaultFunctor "submoduleWithAssertions" // {
      type = submoduleWithAssertions;
      payload = module;
      binOp = lhs: rhs: {
        imports = [lhs rhs];
      };
    };
  };
}