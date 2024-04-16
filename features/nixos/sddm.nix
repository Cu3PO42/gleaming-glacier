{config, lib, copper, pkgs, ...}: {
  services.displayManager.sddm = {
    enable = true;
    theme = "corners";
    # Explicitly use the Qt5 version of SDDM, because that is what the theme is
    # compatible with.
    package = pkgs.libsForQt5.sddm;
    # This is a fix for a huge onscreen keyboard appearing and hiding everything.
    settings.General.InputMethod = "";
    # SDDM theoretically supports getting user icons from AccountsService (which
    # we have set up), but implements it poorly. Instead of actually querying
    # AccountsService for the icon, it hardcodes the path where it will typically
    # place the icons. Since we place them elsewhere, we need to set up icons for
    # SDDM seperately.
    settings.Theme.FacesDir = let
      usersWithIcons = lib.filterAttrs (_: value: value.icon != null) config.users.users;
      # Icons need to end in .face.icon
      iconLinks = lib.mapAttrsToList (name: value: "ln -s ${value.icon} ${name}.face.icon") usersWithIcons;
      icons = pkgs.runCommand "user-icons" {} ''
        mkdir -p $out
        cd $out
        ${lib.concatStringsSep "\n" iconLinks}
      '';
    in "${icons}";
  };

  environment.systemPackages = [
    copper.packages.sddm-theme-corners
  ];
}