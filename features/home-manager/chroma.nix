{pkgs, ...}: {
  copper.chroma = {
    enable = true;
    initialTheme = "Catppuccin-Latte";
  };
  copper.chroma.themes = pkgs.copper.chromaThemes;
}
