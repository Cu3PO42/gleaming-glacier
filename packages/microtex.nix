{
  meson,
  ninja,
  pkg-config,

  tinyxml-2,
  gtkmm3,
  gtksourceviewmm,
  cairomm,
  fontconfig,

  fetchFromGitHub,
  stdenv,
  lib,
  ...
}: let in stdenv.mkDerivation {
  pname = "microtex";
  version = "0.0.5";

  src = fetchFromGitHub {
    owner = "NanoMichael";
    repo = "MicroTeX";
    rev = "d87ebec8436ae01a1eb183d985c1375e39b2a542";
    hash = "sha256-L4bx8x9hobwQQCt8Rsd1ycr0FZfHBbKBJfL3LpZu2HM=";
  };

  buildInputs = [
    gtkmm3
    tinyxml-2
    gtksourceviewmm
    cairomm
    fontconfig
  ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
  ];

  meta = {
    homepage = "https://github.com/NanoMichael/MicroTeX";
    description = "A dynamic, cross-platform, and embeddable LaTeX rendering library.";
    license = lib.licenses.mit;
  };
}