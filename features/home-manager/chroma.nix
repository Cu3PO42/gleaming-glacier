{pkgs, copper, ...}: {
  copper.chroma = {
    enable = true;
    initialTheme = "Catppuccin-Latte";
  };
  copper.chroma.themes = copper.chromaThemes;
}
