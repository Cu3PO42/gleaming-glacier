{
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
      "hyprland"
      "_1password"
    ];

    imports = [
      ./hardware-configuration.nix
    ];

    # Networking configuration
    networking.hostId = "e4c27b74"; # Actually required for ZFS

    # Enable the Plasma 5 Desktop Environment.
    services.xserver.desktopManager.plasma5.enable = true;

    boot.zfs.devNodes = "/dev/mapper/root";

    # Enable the OpenSSH daemon.
    services.openssh.enable = true;
    security.pam.sshAgentAuth.enable = true;

    system.stateVersion = "23.05";
    nixpkgs.hostPlatform = "x86_64-linux";
  };
}