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
      text = "cddt6f4";
      active-highlight = "a6adc8";
      active-text = "313244";
      hover-highlight = palette.accents.pink;
      hover-text = "313244";
    };
  });
}
