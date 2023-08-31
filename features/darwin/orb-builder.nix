{config, ...}: {
  nix.distributedBuilds = true;

  environment.etc."ssh/ssh_config.d/100-linux-builder.conf".text = ''
    Host orb nix-builder
      Hostname localhost
      Port 32222
      StrictHostKeyChecking=accept-new

    Host orb
      User default

    Host nix-builder
      User root@nixos
  '';

  nix.buildMachines = [
    {
      hostName = "nix-builder";
      sshKey = "/Users/${config.defaultUser}/.orbstack/ssh/id_ed25519";
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "i686-linux"
      ];
      supportedFeatures = ["benchmark" "big-parallel"];
      # Each job, by default, can use every core, thus setting this value any
      # higher will cause serious overprovisioning.
      maxJobs = 4;
    }
  ];
}
