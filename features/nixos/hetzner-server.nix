{
  config,
  modulesPath,
  lib,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];

  featureOptions = with lib; {
    ipv6 = mkOption {
      type = types.str;
      example = "2001:db8:abcd:0012::/64";
      description = ''
        The IPv6 block assigned to the server.
      '';
    };
  };

  config = {
    # TODO: generic dependency system?
    assertions = [
      {
        assertion = config.copper.feature.server.enable;
        message = "A Hetzner server must also have the server feature enabled.";
      }
    ];

    boot = {
      # Get a boot log
      kernelParams = ["console=tty"];

      initrd.availableKernelModules = ["xhci_pci" "virtio_pci" "virtio_scsi" "usbhid" "sr_mod"];
      initrd.kernelModules = [
        # Force GPU so that we get early boot output.
        "virtio_gpu"
      ];
    };


    # TODO: this is the interface only for aarch64? might need changes for x64
    systemd.network.networks."10-wan" = {
      matchConfig.Name = "enp1s0";
      networkConfig.DHCP = "ipv4";
      routes = [
        {routeConfig.Gateway = "fe80::1";}
      ];
      address = [
        config.copper.feature.hetzner-server.ipv6
      ];
    };
  };
}
