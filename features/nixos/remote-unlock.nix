{
  origin,
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
    origin.inputs.agenix.nixosModules.age
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
          
          extraConfig = "ForceCommand systemd-tty-ask-password-agent --watch";
        };
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
