# This file is derived from NixOS/nixpkgs/nixos/lib/make-iso9660-image.nix
# It is adjusted not to build the image directly, but to build a script that
# will build it while also including the required secrets that shouldn't be
# placed in the Nix store.

# It was last updated to commit 2a7c323a364c12bd079922cdc4cbe3d9b15f2e03.
# Any changes made are marked with a comment starting with "Adjusted".

{ lib, stdenv, callPackage, closureInfo, xorriso, syslinux, libossp_uuid, squashfsTools

, # Adjusted: added needed input
  writeShellScript, gnused, coreutils

, # The file name of the resulting ISO image.
  isoName ? "cd.iso"

, # The files and directories to be placed in the ISO file system.
  # This is a list of attribute sets {source, target} where `source'
  # is the file system object (regular file or directory) to be
  # grafted in the file system at path `target'.
  contents

, # In addition to `contents', the closure of the store paths listed
  # in `storeContents' are also placed in the Nix store of the CD.
  # This is a list of attribute sets {object, symlink} where `object'
  # is a store path whose closure will be copied, and `symlink' is a
  # symlink to `object' that will be added to the CD.
  storeContents ? []

, # In addition to `contents', the closure of the store paths listed
  # in `squashfsContents' is compressed as squashfs and the result is
  # placed in /nix-store.squashfs on the CD.
  # FIXME: This is a performance optimization to avoid Hydra copying
  # the squashfs between builders and should be removed when Hydra
  # is smarter about scheduling.
  squashfsContents ? []

, # Compression settings for squashfs
  squashfsCompression ? "xz -Xdict-size 100%"

, # Whether this should be an El-Torito bootable CD.
  bootable ? false

, # Whether this should be an efi-bootable El-Torito CD.
  efiBootable ? false

, # Whether this should be an hybrid CD (bootable from USB as well as CD).
  usbBootable ? false

, # The path (in the ISO file system) of the boot image.
  bootImage ? ""

, # The path (in the ISO file system) of the efi boot image.
  efiBootImage ? ""

, # The path (outside the ISO file system) of the isohybrid-mbr image.
  isohybridMbrImage ? ""

, # Whether to compress the resulting ISO image with zstd.
  compressImage ? false, zstd

, # The volume ID.
  volumeID ? ""

  # Adjusted: added input that's needed later.
, # <nixpkgs>/nixos in the store.
  nixosLibPath
}:

assert bootable -> bootImage != "";
assert efiBootable -> efiBootImage != "";
assert usbBootable -> isohybridMbrImage != "";

let
  needSquashfs = squashfsContents != [];
  # Adjusted: make path absolute to nixpkgs
  makeSquashfsDrv = callPackage (nixosLibPath + "/make-squashfs.nix") {
    storeContents = squashfsContents;
    comp = squashfsCompression;
  };

  # Adjusted: added these functions and variables
  exportVariables = vars: let
    escape = val: if lib.isList val then "(${lib.escapeShellArgs val})" else lib.escapeShellArg (builtins.toString val);
  in lib.concatMapStringsSep "\n" (name: ''${name}=${escape vars.${name}}'') (builtins.attrNames vars);

  # Adjusted: added dependencies that are normally in stdenv
  nativeBuildInputs = [ xorriso syslinux zstd libossp_uuid gnused coreutils ]
    ++ lib.optionals needSquashfs makeSquashfsDrv.nativeBuildInputs;

  # Adjusted: moved all of the script inputs here:
  args = {
    inherit isoName bootable bootImage compressImage volumeID efiBootImage efiBootable isohybridMbrImage usbBootable;

    sources = map (x: x.source) contents;
    targets = map (x: x.target) contents;

    objects = map (x: x.object) storeContents;
    symlinks = map (x: x.symlink) storeContents;

    squashfsCommand = lib.optionalString needSquashfs makeSquashfsDrv.buildCommand;

    # For obtaining the closure of `storeContents'.
    closureInfo = closureInfo { rootPaths = map (x: x.object) storeContents; };
  };
in
# Adjusted: new output
writeShellScript "write-plate-image" ''
  ${exportVariables args}
  export PATH=${lib.makeBinPath nativeBuildInputs}:$PATH
  export NIX_BUILD_CORES=$(nproc)
  IFS=: read -a extraSources <<< "$extraSources"
  IFS=: read -a extraTargets <<< "$extraTargets"
  sources+=( "''${extraSources[@]}" )
  targets+=( "''${extraTargets[@]}" )
  # TODO: does this adjustment need to happen to the squashfs build command, too
  source ${./make-iso9660-image.sh}
''