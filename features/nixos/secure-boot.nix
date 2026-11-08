# Enable support for secure boot using Lanzaboote
{
  lib,
  pkgs,
  origin,
  ...
}: {
  imports = [
    origin.inputs.lanzaboote.nixosModules.lanzaboote
  ];

  # Lanzaboote currently replaces systemd-boot, thus we must disable the old
  # implementation.
  boot.loader.systemd-boot.enable = lib.mkForce false;
  # Enable Lanzaboote
  boot.lanzaboote = {
    enable = true;
    # sbctl setup --migrate moves existing key bundles here.
    pkiBundle = "/var/lib/sbctl";
  };

  environment.systemPackages = with pkgs; [
    # Tool to enroll keys and verify signatures
    sbctl
    # Required so that lanzaboote can build correctly
    git
  ];
}
