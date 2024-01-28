{config, lib, inputs, pkgs, ...}: with lib; let
in {
  options = {
    copper.autoload.base = mkOption {
      type = types.path;
      example = literalExpression "./.";
      description = "The base path of the Flake from which to load all elmements.";
    };
  };
  config = {
    perSystem = {...}: {
      apps = import (config.copper.autoload.base + "/apps") (inputs // {inherit pkgs;});
    };
  };
}