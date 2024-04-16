{config, lib, pkgs, ...}: with lib; let
  cfg = config.services.accounts-daemon.defaultSettings;

  templateFile = pkgs.writeText "user-template" (generators.toINI {} cfg);
  templateDir = "share/accountsservice/user-templates";
  templates = pkgs.runCommand "user-templates" {} ''
    mkdir -p $out/${templateDir}
    cd $out/${templateDir}

    ln -s ${templateFile} administrator
    ln -s ${templateFile} standard
  '';
in {
  options.services.accounts-daemon.defaultSettings = mkOption {
    type = types.anything;
    default = {};
    description = ''
      Settings that should be set on by default on the AccountsService cache
      file for a user.
    '';
  };

  config.environment.systemPackages = [templates];
}