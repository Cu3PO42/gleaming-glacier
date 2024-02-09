{
  lib,
  copper,
  ...
}: {
  copper.chroma = {
    enable = true;
    themes.Catppuccin-Mocha = copper.chromaThemes.Catppuccin-Mocha;
    initialTheme = lib.mkDefault "Catppuccin-Mocha";
  };
}
