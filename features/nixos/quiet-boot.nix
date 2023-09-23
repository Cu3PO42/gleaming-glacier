# This module allows for completely silent boot
{pkgs, ...}: {
  boot.kernelParams = [
    # Silences boot messages
    "quiet"
    # Silences successfull systemd messages from the initrd
    "rd.systemd.show_status=false"
    # Silence systemd version number in initrd
    "rd.udev.log_level=3"
    # Silence systemd version number
    "udev.log_priority=3"
    # If booting fails drop us into a shell where we can investigate
    "boot.shell_on_fail"
    # Show a splash screen
    "splash"
  ];
  # Silence dmesg
  boot.consoleLogLevel = 3;
  # Remove extra NixOS logging from the initrd
  boot.initrd.verbose = false;

  # Show a splash screen during boot
  boot.plymouth = let
    theme = "circle_flow";
  in {
    enable = true;
    inherit theme;
    themePackages = [(pkgs.adi1090x-plymouth-themes.override {selected_themes = [theme];})];
  };
}
