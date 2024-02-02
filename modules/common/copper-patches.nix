{config, lib, ...}: with lib; let
  cfg = config.copper.patches;
in {
  options = {
    copper.patches = mkOption {
      type = types.attrsOf (types.listOf (types.submodule {
        options = {
          patch = mkOption {
            type = types.path;
            example = literalExpression ''./0001-fix-zfs-complete.patch'';
            description = ''
              The path to the patch file.
            '';
          };

          condition = mkOption {
            type = types.functionTo types.bool;
            default = _: true;
            example = literalExpression ''fish: fish.version == "1.2.3"'';
            description = ''
              A function that takes the previous version of the package and
              returns a boolean indicating whether the patch should be applied.
            '';
          };
        };
      }));
      default = {};
      description = ''
        Specifies patches to be applied to derivations in nixpkgs using an overlay.
      '';
    };
  };

  config = {
    nixpkgs.overlays = [(final: prev:
      mapAttrs
        (name: value: let
          pkg = prev.${name};
          patches = lib.concatMap (patch: lib.optional (patch.condition pkg) patch.patch) value;
          patched = pkg.overrideAttrs (finalAttrs: prevAttrs: {
            patches = (prevAttrs.patches or []) ++ patches;
          });
        in if builtins.length patches == 0 then pkg else patched)
        cfg
    )];
  };
}