{ config, lib, pkgs, ... }:
{
  options.services.autokbisw = {
    enable = lib.mkEnableOption "Enable autokbisw keyboard switcher daemon";
  };

  config = lib.mkIf config.services.autokbisw.enable {
    launchd.user.agents.autokbisw = {
      serviceConfig = {
        ProgramArguments = [ "${pkgs.autokbisw}/bin/autokbisw" ];
        KeepAlive = true;
        ProcessType = "Interactive";
      };
      managedBy = "services.autokbisw.enable";
    };
  };
}
