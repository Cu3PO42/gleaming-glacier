{
  pkgs,
  makeFontsConf,
  google-fonts,
}: let
  extraFonts = google-fonts.override {
    fonts = [
      "Gabarito"
      "Readex Pro"
      "Space Grotesk"
      "JetBrains Mono"
    ];
  };

  fonts = with pkgs; [
    material-symbols
    nerd-fonts.jetbrains-mono
    nerd-fonts.space-mono
    rubik
    twemoji-color-font
    extraFonts
  ];

  fontConfig = makeFontsConf {
    fontDirectories = fonts;
  };
in fontConfig