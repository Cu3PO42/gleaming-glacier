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
    ];
  };

  fonts = with pkgs; [
    jetbrains-mono
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