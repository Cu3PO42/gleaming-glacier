{
  origin,
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.copper.feature.zfs;
  hasImpermanence = config.copper.feature.impermanence.enable;
in {
  imports = [
    origin.inputs.disko.nixosModules.disko
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

    hasDiskEncryption = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Whether to encrypt the ZFS pool.
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
        Format a single disk at `disko.disk` for use with ZFS and a UEFI system.
      '';
    };

    disko.disk = mkOption {
      type = types.str;
      default = "/dev/sda";
      example = "/dev/nvme0n1";
      description = ''
        The device node of the disk that hosts the filesystem.
      '';
    };

    disko.diskLabel = mkOption {
      type = types.str;
      default = "base";
      example = "sda";
      description = ''
        The label that will be used as part of the constructed partition labels.
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

    copper.patches.fish = [{
      patch = pkgs.fetchpatch {
        name = "fix-zfs-completion.patch";
        url = "https://github.com/fish-shell/fish-shell/commit/85504ca694ae099f023ae0febb363238d9c64e8d.patch";
        sha256 = "sha256-lA0M7E/Z0NjuvppC7GZA5rWdL7c+5l+3SF5yUe7nEz8=";
      };
      condition = fish: config.programs.fish.enable && ((builtins.compareVersions "3.7.0" fish.version) == 1);
    }];

    # Relevant to support Linux 6.4 and newer on aarch64
    boot.zfs.package = lib.mkIf config.boot.zfs.removeLinuxDRM (pkgs.zfs.override { removeLinuxDRM = true; });
    boot.zfs.removeLinuxDRM = pkgs.stdenvNoCC.hostPlatform.isAarch64;

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
        "rpool/user/home" = {
          useTemplate = ["frequent"];
        };

        "rpool/system" = {
          recursive = true;
          useTemplate = ["recent"];
        };
      };
    };

    disko.devices.disk.${cfg.disko.diskLabel} = lib.mkIf cfg.disko.singleDiskFormat {
      type = "disk";
      device = cfg.disko.disk;
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
        // lib.optionalAttrs cfg.hasDiskEncryption {
          encryption = "aes-256-gcm";
          keyformat = "passphrase";
          # TODO: figure out how to factor that out
          keylocation = "file:///tmp/dek.key";
        };
      postCreateHook =
        lib.optionalString hasImpermanence ''
          zfs snapshot -r rpool@blank
        ''
        + lib.optionalString cfg.hasDiskEncryption ''
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
