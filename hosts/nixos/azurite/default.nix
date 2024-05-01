{
  copperConfig = {
    plate = {
      target = "128.140.125.200";
      targetUser = "Cu3PO42";
      hostKey = "op://Servers/Azurite Host Key/private key";
      hostKeyLocation = "/persist/etc/ssh/ssh_host_ed25519_key";
      diskEncryptionKey = "op://Servers/Azurite Disk Encryption Key/password";
      initrdPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGHBOcd/VPlEEb9L5VW5YF1Mn/TiwvLS86Hn15cPgxSN";
      opAccount = "my.1password.eu";
      # The newest NixOS 23.11 release kernel panics on aarch64, so we use the 23.05 release
      extraNixosAnywhereArgs = [
        "--kexec"
        "https://github.com/nix-community/nixos-images/releases/download/nixos-23.05/nixos-kexec-installer-noninteractive-aarch64-linux.tar.gz"
      ];
    };

    mage = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMn/ueI1oSPNHy7NV7CGtviEJi0tDsuGa3CEmlw0rgXt";
      secrets = ./secrets;
    };
  };

  main = {config, pkgs, lib, origin, ...}: {
    copper.features = [
      "hetzner-server"
      "server"
      "locale-de"
      "zfs"
      "remote-unlock"
      "impermanence"
      "home-manager"
      "default-user"
    ];

    copper.feature.zfs = {
      snapshot = true;
      disko = {
        simpleZpool = true;
        singleDiskFormat = true;
      };
    };
    networking.hostId = "6302c2e3";

    copper.feature.remote-unlock.initrdHostKeySecret = ./secrets/initrd_host_ed25519_key.age;
    
    copper.feature.hetzner-server.ipv6 = "2a01:4f8:c17:f3da::/64";

    users.users.Cu3PO42.hashedPasswordFile = config.age.secrets.password-Cu3PO42.path;
    home-manager.users.Cu3PO42 = {
      copper.features = [
        "fish"
        "cli"
        "catppuccin"
        "copilot"
        "git"
        "neovim"
        "lunarvim"
      ];

      home.stateVersion = "23.11";
    };

    zramSwap.enable = true;

    nixpkgs.hostPlatform = "aarch64-linux";
    system.stateVersion = "24.05";
  };
}