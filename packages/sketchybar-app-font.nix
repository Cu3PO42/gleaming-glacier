{
  lib,
  stdenvNoCC,
  fetchurl,
  ...
}:
stdenvNoCC.mkDerivation rec {
  pname = "sketchybar-app-font";
  version = "1.0.11";

  src = fetchurl {
    url = "https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v1.0.12/sketchybar-app-font.ttf";
    hash = "sha256-uQOx3vj0EffjyTvtYvwUxXFyhoASWOBdrVH3kOk0zVs=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    cp ${src} $out/share/fonts/truetype

    runHook postInstall
  '';
}
