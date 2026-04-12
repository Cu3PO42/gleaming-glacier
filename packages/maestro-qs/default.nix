{
  lib,
  stdenv,
  makeWrapper,

  inputs,

  ...
}: let
  quickshell = inputs.quickshell.packages.default;
in stdenv.mkDerivation {
  name = "maestro-qs";

  src = ../../config/maestro;

  nativeBuildInputs = [
    makeWrapper
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/share/maestro-qs
    cp -r ./* $out/share/maestro-qs/

    makeWrapper ${quickshell}/bin/qs $out/bin/maestro-qs \
      --add-flags "-p $out/share/maestro-qs"

    # Wrapper for IPC calls: maestro-qs-ipc call <target> <function> [args...]
    makeWrapper ${quickshell}/bin/qs $out/bin/maestro-qs-ipc \
      --add-flags "-p $out/share/maestro-qs ipc"
  '';

  meta = with lib; {
    description = "Quickshell-based keybind popup for maestro";
    license = licenses.gpl3Only;
    mainProgram = "maestro-qs";
  };
}
