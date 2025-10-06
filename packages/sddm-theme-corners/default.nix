{
  stdenvNoCC,
  qt6,
  fetchFromGitHub,
  lib,
  ...
}:
stdenvNoCC.mkDerivation {
  name = "sddm-theme-corners";
  src = fetchFromGitHub {
    owner = "aczw";
    repo = "sddm-theme-corners";
    rev = "6ff0ff455261badcae36cd7d151a34479f157a3c";
    hash = "sha256-CPK3kbc8lroPU8MAeNP8JSStzDCKCvAHhj6yQ1fWKkY=";
  };
  patches = [ ./0001-chore-upgrade-to-Qt6.patch ];

  propagatedUserEnvPkgs = with qt6; [
    qtwayland
    qtquick3d
    qt5compat
    qtsvg
  ];

  dontConfigure = true;
  dontBuild = true;
  dontWrapQtApps = true;
  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/sddm/themes
    mv ./corners $out/share/sddm/themes
    
    runHook postInstall
  '';

  meta = with lib; {
    description = "A very customizable SDDM theme that places controls on your screen corners.";
    homepage = "https://github.com/aczw/sddm-theme-corners";
    maintainers = ["Cu3PO42"];
    license = licenses.gpl3Only;
  };
}
