{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
  ...
}:
stdenvNoCC.mkDerivation {
  name = "catppuccin-qt5ct";
  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "qt5ct";
    rev = "89ee948e72386b816c7dad72099855fb0d46d41e";
    hash = "sha256-t/uyK0X7qt6qxrScmkTU2TvcVJH97hSQuF0yyvSO/qQ=";
  };
  dontBuild = true;
  installPhase = ''
    mkdir -p $out/share/qt5ct/colors
    mv themes/* $out/share/qt5ct/colors
  '';

  meta = with lib; {
    description = "Catppuccin for the Qt5Ct configuration tool.";
    homepage = "https://github.com/catppuccin/qt5ct";
    license = licenses.mit;
    maintainers = ["Cu3PO42"];
    platforms = platforms.linux;
  };
}
