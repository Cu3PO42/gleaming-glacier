{config, lib, ...}: with lib; let
  cfg = config.copper.patches;
in {
  options = {
    copper.patches = mkOption {
      type = types.attrsOf (types.listOf types.path);
      default = {};
      example = literalExpression ''{ fish = [./0001-fix-zfs-complete.patch]; }'';
      description = ''
        Specifies patches to be applied to derivations in nixpkgs using an overlay.
      '';
    };
  };

  config = {
    nixpkgs.overlays = [(final: prev: mapAttrs (name: value: prev.${name}.overrideAttrs (finalAttrs: prevAttrs: {
      patches = (prevAttrs.patches or []) ++ value;
    }) ) cfg)];
  };
}