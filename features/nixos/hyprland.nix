{
  config,
  origin,
  pkgs,
  copper,
  ...
}: {
  copper.feature.desktop.enable = true;

  programs.hyprland = {
    enable = true;
    # Enable only so we hit the upstream Nix cache. (This setting causes a deviation override.)
    withUWSM = true;
  };
  # xdg-desktop-portal-hyprland is implicitly included by the Hyprland module
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

  programs.dconf.enable = true;

  services.blueman.enable = true;

  fonts.packages = with pkgs.nerd-fonts; [
    caskaydia-cove # Kitty and the desktop monospace font
    jetbrains-mono # WezTerm and Rofi
    ubuntu # Hyprlock
  ];

  # Required to allow swaylock/hyprlock to unlock.
  security.pam.services.swaylock = {};
  security.pam.services.hyprlock = {};

  # Required by end-4's AGS config. I'm not sure what for.
  users.users.${config.copper.feature.default-user.user}.extraGroups = ["video" "input"];
  # To control backlight via DDC.
  hardware.i2c.enable = true;

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
