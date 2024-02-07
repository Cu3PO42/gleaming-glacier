{
  config,
  origin,
  pkgs,
  ...
}: {
  imports = [
    origin.inputs.hyprland.nixosModules.default
  ];

  programs.hyprland = {
    enable = true;
    enableNvidiaPatches = config.copper.feature.nvidia.enable;
  };
  # xdg-desktop-portal-hyprland is implicitly included by the Hyprland module
  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-gtk];

  programs.dconf.enable = true;

  services.blueman.enable = true;

  services.xserver.displayManager.sddm = {
    theme = "corners";
    # This is a fix for a huge onscreen keyboard appearing and hiding everything.
    settings.General.InputMethod = "";
  };
  environment.systemPackages = with pkgs; [
    copper.sddm-theme-corners
    nerdfonts
  ];

  # Required to allow swaylock to unlock.
  security.pam.services.swaylock = {};
}
