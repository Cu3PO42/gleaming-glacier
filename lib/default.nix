{nixpkgs, ...} @ inputs:
let
  misc = import ./misc.nix inputs;
  modules = import ./modules.nix inputs;
  loading = import ./loading.nix inputs;
  strings = import ./strings.nix inputs;
  flake = import ./flake.nix inputs;
  keybinds = import ./keybinds.nix inputs;
  types = import ./types.nix inputs;
in loading // modules // misc // strings // flake // {inherit keybinds types;}
