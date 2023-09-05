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

  meta = {
    platforms = lib.platforms.darwin;
  };
}
