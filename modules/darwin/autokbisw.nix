{ config, lib, pkgs, ... }:
{
  options.services.autokbisw = {
    enable = lib.mkEnableOption "Enable autokbisw keyboard switcher daemon";
  };

  config = lib.mkIf config.services.autokbisw.enable {
    launchd.user.agents.autokbisw = {
      program = "${pkgs.autokbisw}/bin/autokbisw";
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
        StandardOutPath = "/var/log/autokbisw.log";
        StandardErrorPath = "/var/log/autokbisw.log";
      };
    };
  };
}
