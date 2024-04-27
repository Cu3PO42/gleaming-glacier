# Dependencies:
# age, nushell, gum, lsblk, nixos-install, nix, tar, rsync, zfs, systemd, coreutils, nixos-generate-config
{
  writeShellScriptBin,
  lib,
  nushell,

  coreutils,
  age,
  gum,
  gnutar,
  rsync,
  git,
  nix,
  openssh,
  zfs,
  systemd,
  util-linux,
  nixos-install-tools,
  sbctl,
  ...
}: let
  runtimePath = [
    coreutils
    age
    gum
    gnutar
    rsync
    nix
    git
    openssh
    zfs
    systemd
    util-linux
    nixos-install-tools
    sbctl
  ];
in writeShellScriptBin "plate-install" ''
  export PATH=${lib.makeBinPath runtimePath}
  exec ${lib.getExe nushell} ${./plate-install.nu}
''