{copper, ...}: {
  services.xserver.displayManager.sddm = {
    enable = true;
    theme = "corners";
    # This is a fix for a huge onscreen keyboard appearing and hiding everything.
    settings.General.InputMethod = "";
  };

  environment.systemPackages = [
    copper.packages.sddm-theme-corners
  ];
}