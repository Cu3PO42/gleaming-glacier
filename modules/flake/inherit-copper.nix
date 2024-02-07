{config, lib, origin, ...}: with lib; {
  options = {
    copper.inheritModules = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Automatically include all modules from Copper's configuration in the
        system and home configurations constructed by the autoload module and
        enables the respective default feature.
      '';
    };

    copper.base.enable = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Enable the base feature of Copper's configuration, which are generally
        required for the system to function properly.
      '';
    };
  };

  config = {
    gleaming.autoload.baseModules = mkMerge [
      (mkIf config.copper.inheritModules {
        nixos = attrValues origin.nixosModules;
        home = attrValues origin.homeModules;
        darwin = attrValues origin.darwinModules;
      })
      (mkIf config.copper.base.enable {
        nixos = [{ copper.feature.base.enable = lib.mkDefault true; }];
        home = [{ copper.feature.standaloneBase.enable = lib.mkDefault true; }];
        darwin = [{ copper.feature.base.enable = lib.mkDefault true; }];
      })
    ];
  };
}