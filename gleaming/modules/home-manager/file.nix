{
  config,
  lib,
  origin,
  ...
}:
with lib; let
  inherit (origin.config) gleaming;
  cfg = config.${gleaming.basename}.file;

  copy = n: v: {source = gleaming.basepath + "/${v}";};
  symlink = n: v: {source = config.lib.file.mkOutOfStoreSymlink "${cfg.symlink.base}/${v}";};

  mapFile =
    if cfg.symlink.enable
    then symlink
    else copy;
in {
  options = {
    ${gleaming.basename}.file = {
      symlink.enable = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Whether to symlink config files directly from the source rather than
          copying them from the store. This makes it easier to edit those
          files, but harder to revert to a prior state. Due to the way Flakes
          work, you must hardcode the path to the flake by also setting
          `${gleaming.basename}.symlink.base` to the location where you cloned the flake.
        '';
      };

      symlink.base = mkOption {
        type = types.nullOr types.path;
        example = literalExpression "/home/john/dotfiles";
        default = null;
        description = ''
          The location where you have checked out the flake.
        '';
      };

      home = mkOption {
        type = with types; attrsOf str;
        example = literalExpression ''{ ".vimrc" = ../config/.vimrc; }'';
        default = {};
        description = ''
          Files and folders to copy or symlink to the users home directory.
          The value must be a path relative to the Flake root.
        '';
      };

      config = mkOption {
        type = with types; attrsOf str;
        example = literalExpression ''{ ".vimrc" = ../config/.vimrc; }'';
        default = {};
        description = ''
          Files and folders to copy or symlink to the users XDG_CONFIG_HOME.
          The value must be a path relative to the Flake root.
        '';
      };
    };
  };

  config = {
    assertions = [
      {
        assertion = !cfg.symlink.enable || (cfg.symlink.base != null);
        message = "If you enable the symlink option, you must provide a base path.";
      }
    ];

    home.file = mapAttrs mapFile cfg.home;
    xdg.configFile = mapAttrs mapFile cfg.config;
  };
}
