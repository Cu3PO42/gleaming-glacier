{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  is1PR = val: isString val && (builtins.substring 0 5 val) == "op://";

  opRef = mkOptionType {
    name = "1Password Reference";
    description = "A secret reference as expected by the 1Password CLI.";
    descriptionClass = "noun";
    check = is1PR;
    merge = mergeEqualOption;
  };

  orEmpty = val:
    if val == null
    then ""
    else val;

  cfg = config.copper.plate;
in {
  options = {
    copper.plate = {
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
        type = types.nullOr types.path;
	default = null;
        example = ./initrd_host_ed25519_key.pub;
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

          Please note that at the time of writing, the 1Password CLI will
          incorrectly export SSH private keys that are stored as such.
          Instead, you must store the key as text.
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
    };
  };

  config = {
    # need to be specified: target
    assertions = [
      {
        assertion = (cfg.diskEncryptionKey != null) == (cfg.initrdPublicKey != null);
        message = "Specifying an initrd public host key doesn't make sense if FDE isn't enabled.";
      }
    ];

    system.build.plateVars = mkIf (cfg.target != null) (pkgs.writeShellScript "vars.sh" ''
      TARGET="${cfg.target}"
      TARGET_USER="${orEmpty cfg.targetUser}"
      DISK_ENCRYPTION_KEY="${orEmpty cfg.diskEncryptionKey}"
      INITRD_PUBLIC_KEY="${toString (orEmpty cfg.initrdPublicKey)}"
      HOST_KEY="${orEmpty cfg.hostKey}"
      HOST_KEY_LOCATION="${cfg.hostKeyLocation}"
    '');
  };
}
