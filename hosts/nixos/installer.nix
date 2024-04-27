{pkgs, lib, modulesPath, ...}: {
    imports = [
        "${modulesPath}/installer/cd-dvd/installation-cd-graphical-calamares-plasma6.nix"
    ];

    copper.feature.base.enable = false;
    copper.feature.locale-de.enable = true;

    users.users.nixos = {
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEAQlWNszj4j05lq9qjjwYE3oe7JO97Ck9ovw/QUWmJ"
      ];
    };

    environment.systemPackages = with pkgs; [fish];

    nixpkgs.hostPlatform = "x86_64-linux";
}