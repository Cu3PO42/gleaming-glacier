{pkgs, extraArgs, ...}: {
  Catppuccin-Latte = pkgs.callPackage ./catppuccin.nix (extraArgs // {
    variant = "latte";
    accent = "rosewater";

    hyprlandOverrides = palette: {
      active1 = palette.accents.rosewater;
      active2 = palette.accents.mauve;
      inactive1 = palette.accents.lavender;
      inactive2 = palette.accents.teal;
    };

    rofiOverrides = palette: {
      main-background = palette.all.crust;
      highlight = palette.accents.flamingo;
      highlight-text = palette.all.base;
    };

    waybarOverrides = palette: {
      active-text = palette.all.crust;
      hover-highlight = palette.accents.rosewater;
      hover-text = palette.all.crust;
    };

    wallpapers = "${pkgs.fetchgit {
      url = "https://github.com/prasanthrangan/hyde-themes.git";
      rev = "2b526598b76ae613d1de42fd3b089ba919ea6aec"; # Catpuccin-Latte
      hash = "sha256-kjHjcNcktEKLusIey/L4rbychUiib/suxGStq4zg7Pw=";
      sparseCheckout = [
        "Configs/.config/hyde/themes/Catppuccin Latte/wallpapers"
      ];
    }}/Configs/.config/hyde/themes/Catppuccin Latte/wallpapers";
  });

  Catppuccin-Mocha = pkgs.callPackage ./catppuccin.nix (extraArgs // {
    variant = "mocha";

    hyprlandOverrides = palette: {
      # This isn't the same as upstream Hyprdots. It actually uses colors from the Frappe palette.
      active1 = palette.accents.mauve;
      active2 = palette.accents.rosewater;
      inactive1 = palette.accents.lavender;
      inactive2 = "6c7086";
    };

    rofiOverrides = palette: {
      main-background = palette.all.crust;
      text = "cdd6f4";
      border = palette.accents.mauve;
      highlight = palette.accents.lavender;
      highlight-text = palette.all.crust;
    };

    waybarOverrides = palette: {
      main-background = palette.all.crust;
      text = "cdd6f4";
      active-highlight = "a6adc8";
      active-text = "313244";
      hover-highlight = palette.accents.pink;
      hover-text = "313244";
    };

    wallpapers = "${pkgs.fetchgit {
      url = "https://github.com/prasanthrangan/hyde-themes.git";
      rev = "d2052a18ed6e1f9e6d70c3431d27bf94f42be628"; # Catpuccin-Mocha
      hash = "sha256-99wmu1R/Q9tuithyYBlxlEvkixY4Ea6S/Pgdimdqhj4=";
      sparseCheckout = [
        "Configs/.config/hyde/themes/Catppuccin Mocha/wallpapers"
      ];
    }}/Configs/.config/hyde/themes/Catppuccin Mocha/wallpapers";
  });
}
