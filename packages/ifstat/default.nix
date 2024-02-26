# This is a port from the Homebrew formula at https://github.com/Homebrew/homebrew-core/blob/839f41461912cb1ec543f15f09179df02858fca8/Formula/ifstat.rb
{
  lib,
  stdenv,
  fetchurl,
  ...
}: stdenv.mkDerivation {
  pname = "ifstat";
  version = "1.1";

  src = fetchurl {
    url = "http://gael.roualland.free.fr/ifstat/ifstat-1.1.tar.gz";
    hash = "sha256-hZkGO3w5j5z+96nsaZZZslscFNK8D1Na7QXOMrfZ9Qc=";
  };

  # This is necessary since clang 16 upgraded -Wimplcit-int to an error in its
  # default mode. The configure script compiles 'main(){return 0;} to check if
  # the compiler is working, which now fails with the above error. Specifying
  # an older standard is a workaround for this.
  CFLAGS = ["-std=c89"];

  patches = [./64bit.patch];

  configureFlags = [
    "--disable-debug"
    "--disable-dependency-tracking"
    "--mandir=."
  ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share/man/man1/
    cp ifstat $out/bin/ifstat
    mv *.1 $out/share/man/man1/
  '';

  meta = with lib; {
    description = "Tool to report network interface bandwidth";
    homepage = "http://gael.roualland.free.fr/ifstat/";
    platforms = platforms.darwin;
    license = licenses.gpl2Plus;
  };
}
