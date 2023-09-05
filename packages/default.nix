{
  self,
  pkgs ? import ../nixpkgs.nix {},
  ...
} @ inputs:
self.lib.loadDir ./. ({
  path,
  name,
  ...
}: let
  pkg = pkgs.callPackage path {inherit inputs;};
  available = pkgs.lib.meta.availableOn pkgs.hostPlatform pkg;
in
  if available
  then pkg
  else null)
