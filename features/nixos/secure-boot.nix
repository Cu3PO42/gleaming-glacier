# Enable support for secure boot using Lanzaboote
{
  lib,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  # Lanzaboote currently replaces systemd-boot, thus we must disable the old
  # implementation.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  # Generate JSON files describing boot configurations. Required for Lanzaboote
  boot.bootspec.enable = true;
  # Enable Lanzaboote
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/etc/secureboot";
  };

  environment.systemPackages = with pkgs; [
    # Tool to enroll keys and verify signatures
    sbctl
    # Required so that lanzaboote can build correctly
    git
  ];
}
