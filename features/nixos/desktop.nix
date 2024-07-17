{...}: {
  # The name is a remnant of former times. This just enables graphical sessions.
  services.xserver.enable = true;
  # Needed so localectl can work
  services.xserver.exportConfiguration = true;

  # Allow user processes to acquire realtime scheduling priority. Important so things don't get choppy.
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  services.printing.enable = true;

  networking.networkmanager.enable = true;

  environment.sessionVariables = {
    # Enable Wayland support for Electron apps.
    NIXOS_OZONE_WL = "1";
  };
}