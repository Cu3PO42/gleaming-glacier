{lib, origin, ...}: with lib; let
  inherit (origin.lib.types) submoduleWithAssertions;

  is1PR = val: isString val && (builtins.substring 0 5 val) == "op://";

  opRef = mkOptionType {
    name = "1Password Reference";
    description = "A secret reference as expected by the 1Password CLI.";
    descriptionClass = "noun";
    check = is1PR;
    merge = mergeEqualOption;
  };

  plateModule = {config, ...}: {
    options = {
      target = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "1.2.3.4";
        description = ''
          The host that should be installed and updated. Can be referred to by
          IP (v4 or v6), hostname or anything else that allows SSH to resolve
          it.
        '';
      };

      targetUser = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "root";
        description = ''
          The username that should be used when connecting to the target to
          update the configuration. If not specified, the username from which
          you invoke the plate command will be used.
        '';
      };

      diskEncryptionKey = mkOption {
        type = types.nullOr opRef;
        default = null;
        example = "op://My Vault/DEK/value";
        description = ''
          A reference to a 1Password Secret that contains the disk encryption
          passphrase.
        '';
      };

      initrdPublicKey = mkOption {
        type = with types; nullOr (either path str);
        default = null;
        example = ./initrd_host_ed25519_key.pub;
        apply = v: if v == null then null else if isString v then v else builtins.readFile v;
        description = ''
          The location of the public host key that will be used by the initrd
          SSH server used for remote unlocking.
        '';
      };

      hostKey = mkOption {
        type = types.nullOr opRef;
        default = null;
        example = "op://My Vault/Server Host Key/text";
        description = ''
          A reference to a 1Password Secret that contains the unencrypted
          private key that should be used as the host key for a server when
          it is freshly deployed.
        '';
      };

      hostKeyLocation = mkOption {
        type = types.str;
        default = "/etc/ssh/ssh_host_ed25519_key";
        example = "/persist/etc/ssh/ssh_host_ed25519_key";
        description = ''
          The path on the server to install the private key to. The public
          key will be automatically installed to `$\{host_key_location}.pub`.
        '';
      };

      opAccount = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "my.1password.eu";
        description = ''
          This setting controls which 1Password to read the referenced secrets
          from. The account is specified by the 1Password domain in which the
          relevant vaults are located. This is particularly useful when you
          have both a private and a business 1Password account.
          
          If not specified, the default account is used.
        '';
      };

      extraNixosAnywhereArgs = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["--build-on-remote"];
        description = ''
          Additional arguments to pass to `nixos-anywhere` during provision.
        '';
      };

      standaloneHomeManagerUsers = mkOption {
        type = types.listOf types.str;
        default = [];
        example = ["john"];
        description = ''
          A list of configured users that will manager their Home environment
          via Home-Manager, but use it standalone rathar than via the NixOS
          module.
        '';
      };

      secureBootKeys = mkOption {
        type = types.nullOr opRef;
        default = null;
        description = ''
          A 1Password reference to a complete bundle of SecureBoot keys.
        '';
      };
    };

    config = {
      assertions = [
        /*{
          assertion = true || (config.diskEncryptionKey != null) == (config.initrdPublicKey != null);
          message = "Specifying an initrd public host key doesn't make sense if FDE isn't enabled.";
        }*/
      ];
    };
  };
in {
  options.flake.copperConfig = mkOption {
    type = with types; attrsOf (submodule ({config, ...}: {
      options.plate = mkOption {
        type = types.nullOr (submoduleWithAssertions plateModule);
        apply = val: if val == null then null else filterAttrs (name: _: name != "assertions" && name != "warnings") val;
        default = null;
        description = ''
          Configuration for the `plate` tool.
        '';
      };

      config = {
        build.plate = mkIf (config.plate != null) (origin.lib.plate.buildVars config.plate);
      };
    }));
  };
}