{
  lib,
  stdenvNoCC,
  fetchurl,
  ...
}:
stdenvNoCC.mkDerivation rec {
  pname = "sketchybar-app-font";
  version = "2.0.4";

  src = fetchurl {
    url = "https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.4/sketchybar-app-font.ttf";
    hash = "sha256-G3ceScZQT1rrjw+V9ALRo78lSVYsLymQLFfzSo/gA8U=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    cp ${src} $out/share/fonts/truetype

    runHook postInstall
  '';

  meta = with lib; {
    description = "A font of stylized icons of popular macOS applications.";
    homepage = "https://github.com/kvndrsslr/sketchybar-app-font";
    license = licenses.unlicense;
    maintainers = ["Cu3PO42"];
  };
}
