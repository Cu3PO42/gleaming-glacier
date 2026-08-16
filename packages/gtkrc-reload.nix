# A tiny tool to reload the configuration of GTK2 applications.
# It is originally found in the AUR at https://aur.archlinux.org/packages/gtkrc-reload
# and is available under the terms of GPL3 or later.

{stdenv, gtk2, pkg-config, fetchFromGitHub, lib, ...}: stdenv.mkDerivation {
  name = "gtkrc-reload";

  # Upstream is actualld as follows, but since it is often down, we fetch from
  # a mirror.
  # src = fetchgit {
  #  url = "https://aur.archlinux.org/gtkrc-reload.git";
  #  rev = "9ada9f425c86c58e0e5313106178a0869924708f";
  #  hash = "sha256-d/KfA1/Y6LzgDMIrodrf0YnRr/KNii3PAFnxvbJzeME=";
  #};
  src = fetchFromGitHub {
    owner = "neeasade";
    repo = "gtkrc-reload";
    rev = "d9d4fa8b308932d309b59017f7b28a1398ce31db";
    hash = "sha256-ID74QqLYD1YfDqP6NLCMYKZtne3/QV6BSy0C6vzGrO0=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ gtk2 ];

  installPhase = ''
    make install PREFIX=$out
  '';

  meta = with lib; {
    description = "A tiny tool to reload the configuration of GTK2 applications.";
    homepage  = "https://aur.archlinux.org/packages/gtkrc-reload";
    license = licenses.gpl3Plus;
    maintainers = ["Cu3PO42"];
    mainProgram = "gtkrc-reload";
  };
}