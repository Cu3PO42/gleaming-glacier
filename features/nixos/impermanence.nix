{
  inputs,
  config,
  lib,
  ...
}: {
  imports = [
    inputs.impermanence.nixosModules.impermanence
  ];

  environment.persistence."/persist" = {
    directories = [
      "/var/log/journal"
    ];
    files = [
      "/etc/nix/id_rsa"
      "/etc/ssh/ssh_host_ed25519_key"
      "/etc/ssh/ssh_host_ed25519_key.pub"
    ];
  };
  fileSystems."/persist".neededForBoot = true;

  boot.initrd.postDeviceCommands = lib.mkIf config.copper.feature.zfs.enable (lib.mkAfter ''
    zfs rollback -r rpool/local/root@blank && echo "Rollback complete!" || echo "Rollback failed!"
  '');

  # Read from the persistent host key location directly, that fixes some
  # issues during install.
  age.identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
}
