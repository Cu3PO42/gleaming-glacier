{ lib, stdenv, swiftpm2nix, swiftpm, swift, darwinMinVersionHook, ... }:

let
  generated = swiftpm2nix.helpers ./nix;
in stdenv.mkDerivation rec {
  pname = "keybind-helper";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [ swift swiftpm ];

  buildInputs = [(darwinMinVersionHook "13.0")];

  configurePhase = ''
    runHook preConfigure
    ${generated.configure}
    runHook postConfigure
  '';

  installPhase = ''
    runHook preInstall
    
    mkdir -p $out/bin
    binPath=$(swiftpmBinPath)
    cp "$binPath/keybind-helper-daemon" $out/bin
    cp "$binPath/keybind-helper-client" $out/bin

    runHook postInstall
  '';

  meta = with lib; {
    description = "macOS helper to display keybindings, to be used with gleaming-glacier";
    license = licenses.gpl3Only;
    platforms = platforms.darwin;
  };
}
