{
  lib,
  stdenvNoCC,
  fetchurl,
  ...
}:
stdenvNoCC.mkDerivation rec {
  pname = "sketchybar-app-font";
  version = "2.0.39";

  src = fetchurl {
    url = "https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v${version}/sketchybar-app-font.ttf";
    hash = "sha256-kaZv8lrjxsxJQ4/oElnaPype+JpIIyd8U2eYoHmgBM4=";
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
    license = licenses.cc0;
    maintainers = ["Cu3PO42"];
  };
}
