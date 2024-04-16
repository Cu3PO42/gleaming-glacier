{copper, pkgs, ...}: {
  services.displayManager.sddm = {
    enable = true;
    theme = "corners";
    # Explicitly use the Qt5 version of SDDM, because that is what the theme is
    # compatible with.
    package = pkgs.libsForQt5.sddm;
    # This is a fix for a huge onscreen keyboard appearing and hiding everything.
    settings.General.InputMethod = "";
  };

  environment.systemPackages = [
    copper.packages.sddm-theme-corners
  ];
}