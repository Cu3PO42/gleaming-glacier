{
  stdenvNoCC,
  fetchFromGitHub,
}: stdenvNoCC.mkDerivation {
  name = "oneui-icons-4";
  src = fetchFromGitHub {
    owner = "end-4";
    repo = "OneUI4-Icons";
    rev = "693095d45c67e6b48a9873e36af6283f05080e66";
    hash = "sha256-VWgITEJQFbPqIbiGDfDeD0R74y9tCKEfjO/M/tcO94M=";
    fetchSubmodules = true;
  };
  dontBuild = true;
  installPhase = ''
    mkdir -p $out/share/icons
    mv OneUI $out/share/icons
    mv OneUI-dark $out/share/icons
    mv OneUI-light $out/share/icons
  '';
  dontCheckForBrokenSymlinks = true;
}