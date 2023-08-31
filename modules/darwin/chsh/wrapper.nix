{
  stdenv,
  lib,
  users,
}:
stdenv.mkDerivation {
  name = "shell-wrapper";
  src = ./src;
  configurePhase = lib.concatStringsSep "\n" (lib.mapAttrsToList (user: shell: ''echo "case $(id -u ${user}): return \"${shell}\";" >> ./mappings'') users);
  buildPhase = "$CC wrapper.c -o shell-wrapper -O3";
  installPhase = ''
    mkdir -p $out/bin
    cp shell-wrapper $out/bin
  '';
}
