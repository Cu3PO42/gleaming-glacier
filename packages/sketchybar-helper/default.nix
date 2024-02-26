{
  lib,
  stdenv,
  ...
}:
stdenv.mkDerivation {
  name = "sketchybar-helper";
  src = ./src;

  buildPhase = ''
    $CC -v -std=c99 -O3 helper.c -o sketchybar-helper
  '';
  installPhase = ''
    mkdir -p $out/bin
    mv sketchybar-helper $out/bin/
  '';

  meta = with lib; {
    description = "A helper tool to monitor CPU usage for Sketchybar.";
    homepage = "https://github.com/FelixKratz/dotfiles/tree/master/.config/sketchybar/helper";
    maintainers = ["Cu3PO42"];
    license = licenses.gpl3Only;
    platforms = platforms.darwin;
  };
}
