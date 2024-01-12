# A tiny tool to reload the configuration of GTK2 applications.
# It is originally found in the AUR at https://aur.archlinux.org/packages/gtkrc-reload
# and is available under the terms of GPL3 or later.

{stdenv, gtk2, pkg-config, fetchgit, ...}: stdenv.mkDerivation {
  name = "gtkrc-reload";
  src = fetchgit {
    url = "https://aur.archlinux.org/gtkrc-reload.git";
    rev = "9ada9f425c86c58e0e5313106178a0869924708f";
    hash = "sha256-d/KfA1/Y6LzgDMIrodrf0YnRr/KNii3PAFnxvbJzeME=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ gtk2 ];

  installPhase = ''
    make install PREFIX=$out
  '';

  meta.mainProgram = "gtkrc-reload";
}