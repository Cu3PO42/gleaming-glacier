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

  environment.systemPackages = with pkgs; [
    nerdfonts
  ];

  # Required to allow swaylock/hyprlock to unlock.
  security.pam.services.swaylock = {};
  security.pam.services.hyprlock = {};

  services = {
    gvfs.enable = true;
    devmon.enable = true;
    udisks2.enable = true;
    upower.enable = true;
    power-profiles-daemon.enable = true;
    accounts-daemon.enable = true;
    gnome = {
      glib-networking.enable = true;
    };
  };
}
