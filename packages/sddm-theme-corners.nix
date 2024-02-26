{
  stdenvNoCC,
  libsForQt5,
  fetchFromGitHub,
  lib,
  ...
}:
stdenvNoCC.mkDerivation {
  name = "sddm-theme-corners";
  src = fetchFromGitHub {
    owner = "aczw";
    repo = "sddm-theme-corners";
    rev = "a76d4517f163bbc7787f51ab074a0357bbf5e527";
    hash = "sha256-nqQdEdGDc8CHc8m5IypqvYSb4jPen8sH+tr0mMsz9ls=";
  };

  nativeBuildInputs = [libsForQt5.qt5.wrapQtAppsHook];

  buildInputs = [
    libsForQt5.qt5.qtquickcontrols
    libsForQt5.qt5.qtquickcontrols2
    libsForQt5.qt5.qtgraphicaleffects
    libsForQt5.qt5.qtsvg
  ];

  dontBuild = true;
  installPhase = ''
    mkdir -p $out/share/sddm/themes
    mv ./corners $out/share/sddm/themes
  '';

  meta = with lib; {
    description = "A very customizable SDDM theme that places controls on your screen corners.";
    homepage = "https://github.com/aczw/sddm-theme-corners";
    maintainers = ["Cu3PO42"];
    license = licenses.gpl3Only;
  };
}
