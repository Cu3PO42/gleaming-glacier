{config, lib, options, ...}: with lib; let
  cfg = config.copper.mage;

  secretFolder = attrsToList (builtins.readDir cfg.secretFolder);
  secretFiles = (filter (e: e.value == "regular" && hasSuffix ".age" e.name) secretFolder);
  secrets = map (e: removeSuffix ".age" e.name) secretFiles;
in {
  options = {
    copper.mage = {
      secretFolder = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          The host-specific folder where secrets are stored.
        '';
      };
    };
  };

  config = lib.optionalAttrs (options ? age) {
    age.secrets = lib.mkIf (cfg.secretFolder != null) (lib.genAttrs secrets (name: {file = cfg.secretFolder + "/${name}.age";}));
  };
}
