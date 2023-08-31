{
  self,
  pkgs,
  ...
} @ inputs:
self.lib.loadDir ./. (
  {
    path,
    name,
    ...
  }:
    if name == "default"
    then null
    else {
      type = "app";
      program = pkgs.lib.getExe (pkgs.callPackage path {inherit inputs;});
    }
)
