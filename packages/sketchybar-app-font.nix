{
  lib,
  stdenvNoCC,
  fetchurl,
  ...
}:
stdenvNoCC.mkDerivation rec {
  pname = "sketchybar-app-font";
  version = "2.0.51";

  src = fetchurl {
    url = "https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v${version}/sketchybar-app-font.ttf";
    hash = "sha256-Fp4jiSACIZskyn6T7ru21TtA4q78PLLqtWLjkOqyAq8=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    cp ${src} $out/share/fonts/truetype/sketchybar-app-font.ttf

    runHook postInstall
  '';

  meta = with lib; {
    description = "A font of stylized icons of popular macOS applications.";
    homepage = "https://github.com/kvndrsslr/sketchybar-app-font";
    license = licenses.cc0;
    maintainers = ["Cu3PO42"];
  };
}
