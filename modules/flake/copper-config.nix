{lib, ...}: with lib; {
  options.flake.copperConfig = mkOption {
    type = with types; attrsOf (submodule {
      options.build = mkOption {
        type = types.anything;
        default = {};
      };
    });
    default = {};
    description = ''
      Per-host configuration for Copper's external tools.
    '';
  };
}