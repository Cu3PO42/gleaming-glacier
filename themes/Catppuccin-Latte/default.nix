{pkgs, ...}: rec {
  hyprland = {
    files."theme.conf" = ./hyprland.conf;
  };

  waybar = {
    files."theme.css" = ./waybar.css;
  };

  desktop = {
    # Note: this propagatedInputs override should be upstreamed to nixpkgs
    iconTheme.package = pkgs.tela-icon-theme.overrideAttrs (final: prev: {propagatedBuildInputs = prev.propagatedBuildInputs ++ [pkgs.gnome.adwaita-icon-theme pkgs.libsForQt5.breeze-icons];});
    iconTheme.name = "Tela-blue";
    cursorTheme.package = pkgs.bibata-cursors;
    cursorTheme.name = "Bibata-Original-Ice";
    cursorTheme.size = 20;
    font.name = "Cantarell";
    font.size = 10;
    font.package = pkgs.cantarell-fonts;
    monospaceFont.name = "CaskaydiaCove Nerd Font Mono";
    monospaceFont.size = 9;
    monospaceFont.package = pkgs.nerdfonts;
  };

  gtk = {
    theme.package = (pkgs.catppuccin-gtk.override {variant = "latte";}).overrideAttrs (prev: { propagatedUserEnvPkgs = prev.propagatedUserEnvPkgs ++ [ pkgs.gnome.gnome-themes-extra ];});
    theme.name = "Catppuccin-Latte-Standard-Blue-Light";
    documentFont = desktop.font;
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

  fish.theme = {
    file = "${pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "fish";
      rev = "91e6d6721362be05a5c62e235ed8517d90c567c9";
      hash = "sha256-l9V7YMfJWhKDL65dNbxaddhaM6GJ0CFZ6z+4R6MJwBA=";
    }}/themes/Catppuccin Latte.theme";
    name = "Catppuccin Latte";
  };

  starship.palette = {
    file = pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "starship";
      rev = "3e3e54410c3189053f4da7a7043261361a1ed1bc";
      hash = "sha256-soEBVlq3ULeiZFAdQYMRFuswIIhI9bclIU8WXjxd7oY=";
    }
    + /palettes/latte.toml;
    name = "catppuccin_latte";
  };

  bat.theme = {
    src = pkgs.fetchFromGitHub {
      owner = "catppuccin";
      repo = "bat";
      rev = "ba4d16880d63e656acced2b7d4e034e4a93f74b1";
      hash = "sha256-6WVKQErGdaqb++oaXnY3i6/GuH2FhTgK0v4TN4Y0Wbw=";
    };
    file = "Catppuccin-latte.tmTheme";
  };
}
