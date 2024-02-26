{
  stdenv,
  lib,
  users ? {},
  ...
}:
stdenv.mkDerivation {
  name = "macos-shell-wrapper";
  src = ./src;
  configurePhase = lib.concatStringsSep "\n" (lib.mapAttrsToList (user: shell: ''echo "case $(id -u ${user}): return \"${shell}\";" >> ./mappings'') users);
  buildPhase = "$CC wrapper.c -o shell-wrapper -O3";
  installPhase = ''
    mkdir -p $out/bin
    cp shell-wrapper $out/bin
  '';

  meta = with lib; {
    description = "A proxy for user's login shell that works around a race condition with Nix store mounting";
    homepage = "https://github.com/Cu3PO42/gleaming-glacier";
    license = licenses.gpl3Plus;
    maintainers = ["Cu3PO42"];
    platforms = platforms.darwin;
  };
}
