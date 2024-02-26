{bun, stdenvNoCC, ...}: stdenvNoCC.mkDerivation {
  name = "mac-keybind-helper";
  src = ./show-keybind-helper.ts;
  dontUnpack = true;

  buildInputs = [ bun ];

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/show-keybind-helper
  '';
}