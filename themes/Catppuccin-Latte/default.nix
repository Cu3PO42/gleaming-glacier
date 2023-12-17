{pkgs, ...}: {
  hyprland = {
    files."theme.conf" = ./hyprland.conf;
  };

  waybar = {
    files."theme.css" = ./waybar.css;
  };

  gtk = rec {
    theme.package = pkgs.catppuccin-gtk.override {variant = "latte";};
    theme.name = "Catppuccin-Latte-Standard-Blue-Light";
    # Note: this propagatedInputs override should be upstreamed to nixpkgs
    iconTheme.package = pkgs.tela-icon-theme.overrideAttrs (final: prev: {propagatedBuildInputs = prev.propagatedBuildInputs ++ [pkgs.gnome.adwaita-icon-theme pkgs.libsForQt5.breeze-icons];});
    iconTheme.name = "Tela-blue";
    cursorTheme.package = pkgs.bibata-cursors;
    cursorTheme.name = "Bibata-Original-Ice";
    cursorTheme.size = 20;
    font.name = "Cantarell";
    font.size = 10;
    font.package = pkgs.cantarell-fonts;
    documentFont = font;
    monospaceFont.name = "CaskaydiaCove Nerd Font Mono";
    monospaceFont.size = 9;
    monospaceFont.package = pkgs.nerdfonts;
    colorScheme = "light";
  };

  qt = {
    kvantum = {
      package = pkgs.catppuccin-kvantum.override {variant = "Latte";};
      name = "Catppuccin-Latte-Blue";
    };

    qtct = {
      package = pkgs.catppuccin-qt5ct;
      name = "Catppuccin-Latte";
      # TODO: how is the accent color configured?
    };
  };

  kitty = {
    files."theme.conf" = "${pkgs.kitty-themes}/share/kitty-themes/themes/Catppuccin-Latte.conf";
  };

  rofi = {
    files."theme.rasi" = ./rofi.rasi;
  };
}
