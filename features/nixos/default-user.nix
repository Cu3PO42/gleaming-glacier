{config, pkgs, lib, ...}: with lib; let
  cfg = config.copper.feature.default-user;
in {
  featureOptions = {
    user = mkOption {
      type = types.str;
      default = "Cu3PO42";
      description = "The default user to create";
    };
  };
  config = {
    users.users.${cfg.user} = {
      isNormalUser = true;
      home = "/home/${cfg.user}";
      extraGroups = ["wheel"]
        ++ lib.optional config.networking.networkmanager.enable "networkmanager"
        ++ lib.optional config.virtualisation.docker.enable "docker"
        ++ lib.optional config.virtualisation.libvirtd.enable "libvirt";
      shell = pkgs.fish;
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEAQlWNszj4j05lq9qjjwYE3oe7JO97Ck9ovw/QUWmJ"
      ];
      icon = ../../assets/Cu3PO42.png;
    };
  };
}