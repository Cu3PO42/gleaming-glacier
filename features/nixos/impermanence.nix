{
  origin,
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    origin.inputs.impermanence.nixosModules.impermanence
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

  boot.initrd.postDeviceCommands = lib.mkIf (config.copper.feature.zfs.enable && !config.boot.initrd.systemd.enable) (lib.mkAfter ''
    zfs rollback -r rpool/local/root@blank && echo "Rollback complete!" || echo "Rollback failed!"
  '');

  boot.initrd.systemd.services.rollback = lib.mkIf (config.copper.feature.zfs.enable && config.boot.initrd.systemd.enable) {
    description = "Rollback ZFS datasets to a pristine state";
    wantedBy = [
      "initrd.target"
    ]; 
    after = [
      "zfs-import-zroot.service"
    ];
    before = [ 
      "sysroot.mount"
    ];
    path = with pkgs; [
      zfs
    ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      zfs rollback -r rpool/local/root@blank && echo "Rollback complete!" || echo "Rollback failed!"
    '';
  };

  # Read from the persistent host key location directly, that fixes some
  # issues during install.
  age.identityPaths = ["/persist/etc/ssh/ssh_host_ed25519_key"];
}
