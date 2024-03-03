{
  config,
  origin,
  pkgs,
  copper,
  ...
}: {
  imports = [
    origin.inputs.hyprland.nixosModules.default
  ];

  copper.feature.desktop.enable = true;

  programs.hyprland = {
    enable = true;
  };
  # xdg-desktop-portal-hyprland is implicitly included by the Hyprland module
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

  programs.dconf.enable = true;

  services.blueman.enable = true;

  services.xserver.displayManager.sddm = {
    enable = true;
    theme = "corners";
    # This is a fix for a huge onscreen keyboard appearing and hiding everything.
    settings.General.InputMethod = "";
  };
  environment.systemPackages = with pkgs; [
    copper.packages.sddm-theme-corners
    nerdfonts
  ];

  # Required to allow swaylock/hyprlock to unlock.
  security.pam.services.swaylock = {};
  security.pam.services.hyprlock = {};
}
