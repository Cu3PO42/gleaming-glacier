{lib, ...}: with lib; let
  mkConflictOption = name: mkOption {
    type = types.str;
    default = "";
    description = ''
      This option is used to ensure you enable at most one ${name}.

      It should never be read.
    '';
  };
in {
  options.copper.desktopEnvironment = {
    notificationDaemon = mkConflictOption "notification daemon";

    polkitAgent = mkConflictOption "polkit agent";

    systemTray = mkConflictOption "system tray";
  };
}