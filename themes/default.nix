{pkgs, ...}: {
  Catppuccin-Latte = import ./Catppuccin-Latte {inherit pkgs;};
  Catppuccin-Mocha = import ./Catppuccin-Mocha {inherit pkgs;};
}
