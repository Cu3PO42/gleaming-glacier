{
  self,
  pkgs ? import ../nixpkgs.nix {},
  ...
} @ inputs:
self.lib.loadDir ./. ({
    path,
    name,
    ...
  }:
    if name == "default"
    then null
    else pkgs.callPackage path {inherit inputs;})
