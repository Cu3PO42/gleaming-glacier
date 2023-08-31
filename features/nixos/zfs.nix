{
  inputs,
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.copper.feature.zfs;
  hasImpermanence = config.copper.feature.impermanence.enable;
  hasDiskEncryption = true;
in {
  imports = [
    inputs.disko.nixosModules.disko
  ];

  featureOptions = with lib; {
    snapshot = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Create ZFS snapshots using Sanoid.
      '';
    };

    disko.simpleZpool = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Sets up a simple zpool within the disko disk formatting system.
      '';
    };

    disko.singleDiskFormat = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Format a single disk at /dev/sda for use with ZFS and a UEFI system.
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = config.networking.hostId != null;
        message = "When using ZFS, you must specify `networking.hostId`.";
      }
    ];

    boot.supportedFilesystems = ["zfs"];
    # Since ZFS lives out of tree, we can't always run the latest kernel
    boot.kernelPackages = config.boot.zfs.package.latestCompatibleLinuxPackages;

    nixpkgs.overlays = lib.mkIf config.programs.fish.enable [
      (final: prev: {
        fish = prev.fish.overrideAttrs (o: {
          patches =
            (o.patches or [])
            ++ [
              (pkgs.fetchpatch {
                name = "fix-zfs-completion.path";
                url = "https://github.com/fish-shell/fish-shell/commit/85504ca694ae099f023ae0febb363238d9c64e8d.patch";
                sha256 = "sha256-lA0M7E/Z0NjuvppC7GZA5rWdL7c+5l+3SF5yUe7nEz8=";
              })
            ];
        });
      })
    ];

    # This will need to be enabled as soon as we have a ZFS version with support for 6.4
    #zfs.removeLinuxDRM = true;

    services.sanoid = lib.mkIf cfg.snapshot {
      enable = true;
      templates = {
        frequent = {
          hourly = 24;
          daily = 7;
          monthly = 12;
          yearly = 2;
          autoprune = true;
          autosnap = true;
        };

        recent = {
          hourly = 24;
          daily = 7;
          autoprune = true;
          autosnap = true;
        };
      };
      datasets = {
        "user/home" = {
          useTemplate = ["frequent"];
        };

        system = {
          recursive = true;
          useTemplate = ["recent"];
        };
      };
    };

    disko.devices.disk.sda = lib.mkIf cfg.disko.singleDiskFormat {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot/efi";
            };
          };
          zfs = {
            size = "100%";
            content = {
              type = "zfs";
              pool = "rpool";
            };
          };
        };
      };
    };

    disko.devices.zpool.rpool = lib.mkIf cfg.disko.simpleZpool {
      type = "zpool";
      mode = "";
      rootFsOptions =
        {
          compression = "on";
          mountpoint = "none";
        }
        // lib.optionalAttrs hasDiskEncryption {
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          # TODO: figure out how to factor that out
          keylocation = "file:///tmp/dek.key";
        };
      postCreateHook =
        lib.optionalString hasImpermanence ''
          zfs snapshot -r rpool@blank
        ''
        + lib.optionalString hasDiskEncryption ''
          # During boot, ask for the key.
          zfs set keylocation="prompt" "rpool"
        '';

      datasets = {
        local = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        system = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };
        user = {
          type = "zfs_fs";
          options.mountpoint = "none";
        };

        "local/nix" = {
          type = "zfs_fs";
          mountpoint = "/nix";
          options = {
            atime = "off";
          };
        };

        "local/root" = {
          type = "zfs_fs";
          mountpoint = "/";
        };

        "system/varlib" = {
          type = "zfs_fs";
          mountpoint = "/var/lib";
          options = {
            xattr = "sa";
            acltype = "posixacl";
          };
        };

        "system/persist" = lib.mkIf hasImpermanence {
          type = "zfs_fs";
          mountpoint = "/persist";
        };

        "user/home" = {
          type = "zfs_fs";
          mountpoint = "/home";
        };
      };
    };
  };
}
