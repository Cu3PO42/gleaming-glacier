{config, pkgs, lib, ...}: with lib; let
  cfg = config.copper.feature.default-user;
in {
  featureOptions = {
    user = mkOption {
      type = types.str;
      default = "Cu3PO42";
      description = "The default user to create";
    };

    publicKeys = mkOption {
      type = with types; listOf str;
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMEAQlWNszj4j05lq9qjjwYE3oe7JO97Ck9ovw/QUWmJ"
      ];
      description = "Public keys to set for authorization of this user.";
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
      openssh.authorizedKeys.keys = cfg.publicKeys;
      hashedPasswordFile = mkIf (config ? age.secrets."${cfg.user}-password") config.age.secrets."${cfg.user}-password".path;
      icon = ../../assets/Cu3PO42.png;
    };
  };
}