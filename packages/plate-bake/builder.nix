{
  installerSystem,
  targetFlake,
  targetSystem,
  outputName,
  homeConfigs,
  plate-installer,
}: let
  homeProfiles = builtins.map (c: {
    inherit (c) user;
    profile = targetFlake.homeConfigurations.${c.attribute}.activationPackage;
  }) homeConfigs;
  final = installerSystem.extendModules {
    modules = [
      ({config, lib, pkgs, modulesPath, ...}: {
        # Enable "standard" settings needed for plate-install.
        nix.settings.experimental-features = ["nix-command" "flakes"];

        # Include the target system closure in the store.
        # Also include the sources needed to build it, in case we want to patch it.
        isoImage.storeContents = let
          recurse = flk: if (flk._type or "") == "flake" then [flk.sourceInfo.outPath] ++ lib.concatMap (recurse) (builtins.attrValues flk.inputs) else [flk.outPath];
        in [targetSystem.config.system.build.toplevel] ++ recurse targetFlake
          # For some reason the script is not included automatically. Do it manually.
          ++ [targetSystem.config.system.build.diskoScript]
          # HM configs probably behave the same way.
          ++ builtins.map (e: e.profile) homeProfiles;

        isoImage.contents = [
          {
            source = pkgs.writeText "config.json" (builtins.toJSON {
              inherit outputName;
              system = builtins.toString targetSystem.config.system.build.toplevel;
              boot = {
                inherit (targetSystem.config.boot) kernelModules extraModulePackages;
                initrd = { inherit (targetSystem.config.boot.initrd) availableKernelModules kernelModules; }; 
              };
              secureBoot = if targetSystem.options ? boot.lanzaboote && targetSystem.config.boot.lanzaboote.enable then {
                inherit (targetSystem.config.boot.lanzaboote) pkiBundle;
              } else null;
              disko = if targetSystem.options ? disko && targetSystem.config.disko.devices.disk != {} then {
                devices = let disks = targetSystem.config.disko.devices.disk; in builtins.map (name: disks.${name}.device) (builtins.attrNames disks);
                script = targetSystem.config.system.build.diskoScript;
                encryption = targetSystem.config.copper.feature.zfs.hasDiskEncryption;
                encryptionKeyPath = "/run/plate/secrets/tmp/dek.key";
              } else null;
              homeManager.profiles = homeProfiles;
            });
            target = "/plate/config.json";
          }
        ];

        environment.systemPackages = [
          plate-installer
        ];

        system.build.plateImageBuilder = with lib; let
          # These are the same args that are passed to make-iso9660-image in
          # iso-image.nix.
          args = {
            inherit (config.isoImage) isoName compressImage volumeID contents;
            bootable = config.isoImage.makeBiosBootable;
            bootImage = "/isolinux/isolinux.bin";
            syslinux = if config.isoImage.makeBiosBootable then pkgs.syslinux else null;
            squashfsContents = config.isoImage.storeContents;
            squashfsCompression = config.isoImage.squashfsCompression;
          } // optionalAttrs (config.isoImage.makeUsbBootable && config.isoImage.makeBiosBootable) {
            usbBootable = true;
            isohybridMbrImage = "${pkgs.syslinux}/share/syslinux/isohdpfx.bin";
          } // optionalAttrs config.isoImage.makeEfiBootable {
            efiBootable = true;
            efiBootImage = "boot/efi.img";
          };
        in pkgs.callPackage ./make-iso9660-image-builder.nix (args // {nixosLibPath = modulesPath + "/../lib";});
      })
    ];
  };
in final.config.system.build.plateImageBuilder