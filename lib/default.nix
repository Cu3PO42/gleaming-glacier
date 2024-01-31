{nixpkgs, ...} @ inputs:
let
  misc = import ./misc.nix inputs;
  modules = import ./modules.nix inputs;
  loading = import ./loading.nix inputs;
  strings = import ./strings.nix inputs;
in loading // modules // misc // strings
