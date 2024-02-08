{
  origin,
  config,
  pkgs,
  copper,
  ...
}: {
  # General Nix settings
  nix.settings.experimental-features = ["nix-command" "flakes"];
  # We pin the system's nixpkgs to what we have in the Flake.
  # Both in the Flake registry, so nixpkgs resolves to our version by default
  # and when used with a command such as `nix run nixpkgs#hello`, but also
  # create a channel pointing to the same version.
  nix.registry.nixpkgs.flake = origin.inputs.nixpkgs;
  nix.nixPath = [
    "nixpkgs=/etc/channels/nixpkgs"
  ];
  environment.etc."channels/nixpkgs".source = origin.inputs.nixpkgs.outPath;

  # This modifies the packages that are available to install as part of this
  # system configuration only.
  nixpkgs.config.allowUnfree = true;

  # command-not-found relies on a programs.sqlite database that is only
  # available from channels, but not importing nixpkgs in a flake.
  # While it is possible to manually extract and supply this file, it is now
  # generated via nix-index anyway, so we just use that directly instead.
  programs.command-not-found.enable = false;

  # nix-index provides a command-not-found implementation as well as
  # nix-locate, which helps with finding the package a binary is contained in.
  programs.nix-index.enable = true;
  # Instead of manually building the database on every host, we grab a
  # pre-built one.
  programs.nix-index.package = copper.inputs.nix-index-database.nix-index-with-db;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

  # Make every root user trusted.
  nix.settings.trusted-users = let
    usernames = builtins.attrNames config.users.users;
    pred = user: builtins.elem "wheel" config.users.users.${user}.extraGroups;
    wheels = builtins.filter pred usernames;
  in
    wheels;

  boot.loader = {
    # Use the systemd-boot EFI boot loader.
    systemd-boot.enable = true;
    # Disable command line editing because it allows root access
    systemd-boot.editor = false;
    timeout = 1;
    efi.efiSysMountPoint = "/boot/efi";
    efi.canTouchEfiVariables = true;
  };

  # List packages installed in system profile.
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
  ];

  programs.fish.enable = true;
  programs.zsh.enable = true;
}
