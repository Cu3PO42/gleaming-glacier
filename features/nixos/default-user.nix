{config, pkgs, lib, ...}: {
  users.users.Cu3PO42 = {
    isNormalUser = true;
    home = "/home/Cu3PO42";
    extraGroups = ["wheel"] ++ lib.optional config.networking.networkmanager.enable "networkmanager";
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEAQlWNszj4j05lq9qjjwYE3oe7JO97Ck9ovw/QUWmJ"
    ];
  };
}