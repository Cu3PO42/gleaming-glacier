{...}: {
  boot = {
    # Get a boot log
    kernelParams = ["console=tty"];

    initrd.kernelModules = [
      # Force GPU so that we get early boot output.
      "virtio_gpu"
    ];
  };

  # Prevent root login
  users.users.root.hashedPassword = null;
  users.mutableUsers = false;

  # Needed so we can use our provisioning script.
  security.pam.enableSSHAgentAuth = true;

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
    hostKeys = [
      # No RSA host keys.
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };

  services.fail2ban.enable = true;

  systemd.network.enable = true;

  networking = {
    firewall.enable = true;
  };
}
