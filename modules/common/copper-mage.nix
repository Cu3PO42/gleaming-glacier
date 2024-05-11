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


  config = let
    copperConfig = config.gleaming.autoload.entry.copperConfig or {};
  in {
    copper.mage.secretFolder = mkIf (copperConfig ? mage) copperConfig.mage.secrets;
  } // optionalAttrs (options ? age) {
    # TODO: this isn't totally DRY because we duplicate the hostKeyLocation default
    age.identityPaths = mkIf (copperConfig.plate.hostKey or null != null) (mkDefault [(copperConfig.plate.hostKeyLocation or "/etc/ssh/ssh_host_ed25519_key")]);
    age.secrets = mkIf (cfg.secretFolder != null) (genAttrs secrets (name: {file = cfg.secretFolder + "/${name}.age";}));
  };
}
