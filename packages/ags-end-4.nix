{
  python3,
  dart-sass,
  gtksourceview3,
  webp-pixbuf-loader,
  google-fonts,

  stdenvNoCC,
  fetchFromGitHub,
  writeShellApplication,

  self,
  pkgs,
  inputs,
  lib,
  ...
}: with lib; let
  oneUiIcons = stdenvNoCC.mkDerivation {
    name = "oneui-icons-4";
    src = fetchFromGitHub {
      owner = "end-4";
      repo = "OneUI4-Icons";
      rev = "9ba21908f6e4a8f7c90fbbeb7c85f4975a4d4eb6";
      hash = "sha256-f5t7VGPmD+CjZyWmhTtuhQjV87hCkKSCBksJzFa1x1Y";
      fetchSubmodules = true;
    };
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/icons
      mv OneUI $out/share/icons
      mv OneUI-dark $out/share/icons
      mv OneUI-light $out/share/icons
    '';
  };

  extraFonts = google-fonts.override {
    fonts = [
      "Gabarito"
      "Readex Pro"
    ];
  };

  dots = fetchFromGitHub {
    owner = "end-4";
    repo = "dots-hyprland";
    rev = "f7fe6064e2cdf7cd95e3834664b9580ecb6e2f51";
    hash = "sha256-YZjNhIxlVZdSPI8H0IjQ2z24kSxpn/5x8eI3BG9vDJA=";
  };

  agsConfig = stdenvNoCC.mkDerivation {
    name = "ags-config-end-4";
    src = dots + "/.config/ags";

    buildInputs = [
      pythonEnv
    ];

    buildPhase = ''
      echo "" > ./scss/_musicwal.scss
      echo "" > ./scss/_musicmaterial.scss
    '';

    installPhase = ''
      mkdir $out
      mv ./* $out
    '';
  };

  pythonEnv = python3.withPackages (ps: with ps; [
    pywal
    self.materialyoucolor
    pywayland
    psutil
  ]);

  ags = (inputs.ags.packages.default.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [
      gtksourceview3
      webp-pixbuf-loader
    ];
  }));

  sharePaths = with pkgs; [
    jetbrains-mono
    material-symbols
    nerdfonts
    rubik
    bibata-cursors
    extraFonts
  ];

in (writeShellApplication {
  name = "ags-end-4";
  runtimeInputs = with pkgs; [
    ags
    dart-sass
    swappy
    wf-recorder
    grim
    tesseract4
    slurp
    wl-clipboard
    hyprpicker
    upower
    yad
    ydotool
    pavucontrol
    brightnessctl
    wlsunset
    pythonEnv
    oneUiIcons
    gojq
  ];

  text = ''
    export XDG_DATA_DIRS="${concatMapStringsSep ":" (p: p + "/share") (sharePaths ++ [oneUiIcons])}:$XDG_DATA_DIRS"
    ags -c "${agsConfig}/config.js"
  '';
}).overrideAttrs (old: {
  propagatedUserEnvPkgs = sharePaths;
})