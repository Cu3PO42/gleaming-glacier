{
  stdenvNoCC,
  lib,
  makeWrapper,
  nushell,

  gnutar,
  gum,
  nix,
  git,
  openssh,
  dos2unix,
  age,
  coreutils,

  self,
  ...
}: let
  runtimePath = [
    gnutar
    gum
    nix
    git
    openssh
    dos2unix
    age
    coreutils
    self.op-proxy
  ];
in stdenvNoCC.mkDerivation {
  name = "plate-bake";
  src = ./.;

  nativeBuildInputs = [makeWrapper];
  buildInputs = [nushell];

  buildPhase = ''
    substituteInPlace ./plate-bake.nu \
      --replace-fail '@BUILDER_NIX@' '${placeholder "out"}/support/builder.nix' \
      --replace-fail '@PLATE_INSTALLER@' ${self.plate-install}
  '';

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/support

    mv plate-bake.nu $out/bin/plate-bake
    wrapProgram $out/bin/plate-bake --prefix PATH : ${lib.makeBinPath runtimePath}

    mv ./* $out/support 
    rm $out/support/default.nix
  '';
}