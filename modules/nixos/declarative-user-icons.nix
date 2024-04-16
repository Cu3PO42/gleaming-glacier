# This file is based on the following comment by jonathan-conder:
# https://github.com/NixOS/nixpkgs/issues/163080#issuecomment-1722465663
# The original comment has the limitation that updates to icons would not
# necessarily be picked up. This should be rectified by my version.

{config, lib, pkgs, ...}: with lib; let
  userIconsPath = "/etc/user-icons";

  usersWithIcons = lib.filterAttrs (_: value: value.icon != null) config.users.users;
  iconLinks = lib.mapAttrsToList (name: value: "ln -s ${value.icon} ${name}") usersWithIcons;
  icons = pkgs.runCommand "user-icons" {} ''
    mkdir -p $out${userIconsPath}
    cd $out${userIconsPath}
    ${concatStringsSep "\n" iconLinks}
  '';
in {
  options.users.users = mkOption {
    type = types.attrsOf (types.submodule {
      options.icon = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          An icon to use for the user in their login manager and other UIs.
        '';
      };
    });
  };

  config = {
    services.accounts-daemon.defaultSettings.User.Icon = "/run/current-system/sw${userIconsPath}/\${USER}";

    environment.pathsToLink = [userIconsPath];

    environment.systemPackages = [icons];
  };
}
