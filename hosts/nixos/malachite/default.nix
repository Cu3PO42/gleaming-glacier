{
  copperConfig.plate = {
    standaloneHomeManagerUsers = ["Cu3PO42"];
    secureBootKeys = "op://Private/Malachite Secure Boot Keys/sbkeys";
    hostKey = "op://Private/Malachite Host Key/private key";
    diskEncryptionKey = "op://Private/Malachite Disk Encryption Key/password";
  };

  main = {
    copper.features = [
      "base"
      "default-user"
      "locale-de"
      "amd"
      "zfs"
      "quiet-boot"
      "luks-tpm"
      "secure-boot"
      "sddm"
      "hyprland"
      "_1password"
    ];

    imports = [
      ./hardware-configuration.nix
    ];

    # Networking configuration
    networking.hostId = "e4c27b74"; # Actually required for ZFS

    services.desktopManager.plasma6.enable = true;

    copper.feature.zfs = {
      disko = {
        disk = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_1TB_S5H9NS0N837254Z";
        simpleZpool = true;
        singleDiskFormat = true;
      };
    };
    boot.zfs.devNodes = "/dev/disk/by-id";

    virtualisation.docker.enable = true;

    # Enable the OpenSSH daemon.
    services.openssh.enable = true;
    security.pam.sshAgentAuth.enable = true;

    virtualisation.libvirtd.enable = true;
    virtualisation.libvirtd.qemu.ovmf.enable = true;
    programs.virt-manager.enable = true;

    hardware.bluetooth.enable = true;

    system.stateVersion = "24.05";
    nixpkgs.hostPlatform = "x86_64-linux";
  };
}
