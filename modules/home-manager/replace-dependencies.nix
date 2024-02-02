# This module provides the equivalent of system.replaceRuntimeDependencies, but
# for home-manager.
{pkgs, lib, config, ...}: with lib; let
  cfg = config.home;

  # This is copied from upstream home-manager/modules/home-environment.nix.
  # This should ideally be upstreamed.
  path = pkgs.buildEnv {
    name = "home-manager-path";

    paths = cfg.packages;
    inherit (cfg) extraOutputsToInstall;

    postBuild = cfg.extraProfileCommands;

    meta = {
      description = "Environment of packages installed through home-manager";
    };
  };

  patchedPath = pkgs.copper.replace-dependencies { drv = path; replacements = cfg.replaceRuntimeDependencies; };
in {
  options = {
    home.replaceRuntimeDependencies = mkOption {
      type = with types; listOf (submodule {
        options = {
          original = mkOption {
            type = package;
            description = "The original package to override.";
          };

          replacement = mkOption {
            type = package;
            description = "The replacement package.";
          };
        };
      });
      default = [];
      example = literalExpression ''
        [
          {
            original = pkgs.libadwaita;
            replacement = pkgs.copper.libadwaita-without-adwaita;
          }
        ]
      '';
      apply = map ({ original, replacement, ... }: {
        oldDependency = original;
        newDependency = replacement;
      });
      description = ''
        List of packages to override without doing a full rebuild. The original
        derivation and replacement derivation must have the same name length,
        and ideally should have close-to-identical directory layout.
      '';
    };
  };
  config = {
    home.path = mkIf (cfg.replaceRuntimeDependencies != []) (mkForce patchedPath);
  };
}