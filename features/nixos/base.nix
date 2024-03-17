{
  origin,
  config,
  pkgs,
  copper,
  lib,
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

  # Enable NixOS to run non-NixOS binaries with a custom dynamic linker.
  programs.nix-ld.enable = true;
  programs.nix-ld.package = copper.inputs.nix-ld-rs;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. This value is host-specific and should never
  # be updated. Thus, it should defined in the host configuration and not
  # any module. It was erroneously defined here in the past. This default
  # is deprecated.
  system.stateVersion = let
    msg = "You should always set `system.stateVersion` yourself because it is a host-specific property. Relying on a default is incorrect.";
  in lib.mkDefault (lib.warn msg "23.05");

  # Make every root user trusted.
  nix.settings.trusted-users = let
    usernames = builtins.attrNames config.users.users;
    pred = user: builtins.elem "wheel" config.users.users.${user}.extraGroups;
    wheels = builtins.filter pred usernames;
  in
    wheels;

  boot.loader = {
    # Use the systemd-boot EFI boot loader.
    systemd-boot.enable = lib.mkDefault true;
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

  # Enable auth via SSH agent only with system-managed keys.
  # This is a fix for nixpkgs#31611.
  security.pam.sshAgentAuth.authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
}
