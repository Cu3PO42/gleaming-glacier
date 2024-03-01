{config, lib, origin, ...}: with lib; let
  inherit (origin.lib.types) submoduleWithAssertions;

  mageModule = {
    options = {
      publicKey = mkOption {
        type = types.str;
        description = ''
          The public key that secrets are encrypted with.
        '';
      };

      secrets = mkOption {
        type = types.path;
        example = literalExpression "./secrets";
        description = ''
          The folder for host-specific secrets.
        '';
      };
    };
  };
in {
  options.flake.copperConfig = mkOption {
    type = with types; attrsOf (submodule ({config, ...}: {
      options.mage = mkOption {
        type = types.nullOr (submoduleWithAssertions mageModule);
        default = null;
        description = ''
          Configuration for the mage secret management abstraction.
        '';
      };
    }));
  };
}