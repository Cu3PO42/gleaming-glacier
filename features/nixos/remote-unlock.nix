{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.copper.feature.remote-unlock;

  zfsUnlockScript = ''
  '';
in {
  imports = [
    inputs.agenix.nixosModules.age
  ];

  featureOptions = with lib; {
    initrdHostKeySecret = mkOption {
      type = types.path;
      example = literalExpression "./secrets/initrd_host_ed25519_key.age";
      description = ''
        An age file for a secret containing the SSH host key used by the SSH
        server in the initrd.
      '';
    };
  };

  config = {
    boot.initrd = {
      network = {
        enable = true;
        ssh = {
          enable = true;
          # Against common advice, use the normal SSH port since other ports are blocked by our corporate network.
          # We manually specify a different known hosts file for the unlocking operation.
          port = 22;
          hostKeys = [
            config.age.secrets."initrd_host_ed25519_key".path
          ];
          authorizedKeys = let
            usernames = builtins.attrNames config.users.users;
            pred = user: builtins.elem "wheel" config.users.users.${user}.extraGroups;
            wheels = builtins.filter pred usernames;
          in
            lib.concatMap (user: config.users.users.${user}.openssh.authorizedKeys.keys) wheels;
          
          extraConfig = lib.mkIf config.boot.initrd.systemd.enable "ForceCommand systemd-tty-ask-password-agent --watch";
        };

        postCommands = lib.mkIf (config.copper.feature.zfs.enable && !config.boot.initrd.systemd.enable) ''
          cat <<EOF > /root/.profile
          if pgrep -x "zfs" > /dev/null
          then
            if zfs load-key -a; then
              killall zfs
            else
              echo "zfs passphrase invalid. Please try again."
            fi
          else
            echo "zfs not running -- maybe the pool is taking some time to load for some unforseen reason."
          fi
          EOF
        '';
      };

      systemd.network = lib.mkDefault config.systemd.network;
    };

    age.secrets."initrd_host_ed25519_key" = {
      file = cfg.initrdHostKeySecret;
      # We use a non-standard path due to ryantm/agenix#193.
      path = "/etc/ssh/initrd_host_ed25519_key";
      # Symlinking seems to cause some issues during installation.
      symlink = false;
    };
  };
}
