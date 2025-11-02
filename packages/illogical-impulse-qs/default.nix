{
  lib,
  pkgs,
  fetchFromGitHub,
  callPackage,

  makeWrapper,
  makeFontsConf,
  stdenv,

  python312,
  xkeyboard_config,
  qt6,
  kdePackages,
  bibata-cursors,
  gsettings-desktop-schemas,

  inputs,

  ...
}: let
  oneUiIcons = callPackage ./oneui.nix {};
  pythonEnv = callPackage ./python-env.nix { python = python312; };
  fontConfig = callPackage ./fonts.nix {};
  packages = (callPackage ./packages.nix {}).allPackages;

  quickshell = inputs.quickshell.packages.default;

  src = fetchFromGitHub {
    owner = "end-4";
    repo = "dots-hyprland";
    rev = "dcc14a565d191468e4d2ff1c983a6a73f470da32";
    hash = "sha256-Nd3iv0bWL2vCSPDKzfSZAmfXDHJexGomPdi/t/5V7BA=";
    fetchSubmodules = true;
  };

  # TODO: include fonts as well?
  sharePaths = [
    bibata-cursors
    oneUiIcons
  ];

  runtimeDependencies = packages ++ [pythonEnv];

in stdenv.mkDerivation {
  name = "illogical-impulse";
  src = src + "/dots/.config/quickshell/ii";

  nativeBuildInputs = [
    makeWrapper
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    quickshell
    xkeyboard_config
    qt6.qtbase
    kdePackages.qt5compat
    kdePackages.qtdeclarative
    kdePackages.kdialog
    kdePackages.qtwayland
    kdePackages.qtpositioning
    kdePackages.qtlocation
    kdePackages.syntax-highlighting
  ];

  prePatch = ''
    #substituteInPlace 'Translation.qml' --replace 'Qt.resolvedUrl(Directories.config + "/quickshell/translations/")' "\"$out/share/ii/translations/\""
    (
      shopt -s globstar
      for file in **/*.py; do
        substituteInPlace "$file" --replace '#!/usr/bin/env -S\_/bin/sh\_-c\_"source\_\$(eval\_echo\_\$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec\_python\_-E\_"\$0"\_"\$@""' "#!${pythonEnv}/bin/python"
      done
    )
    cp ${./switchwall.sh} scripts/colors/switchwall.sh
    cp ${./Background.qml} modules/background/Background.qml
  '';

  dontConfigure = true;
  dontBuild = true;

  propagatedBuildInputs = runtimeDependencies;

  installPhase =  let
    wrapperArgs = ''
      --set FONTCONFIG_FILE ${fontConfig} \
      --prefix XDG_DATA_DIRS : ${lib.makeSearchPath "share" sharePaths} \
      --prefix XDG_DATA_DIRS : ${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name} \
      --set ILLOGICAL_IMPULSE_VIRTUAL_ENV ${pythonEnv.fakeVenv} \
      --set MATUGEN_DIR $out/share/matugen \
      --set II_SCRIPT_DIR $out/share/ii/scripts \
      --prefix PATH : $out/bin/support:${lib.makeBinPath runtimeDependencies}
    '';
  in ''
    mkdir -p $out/share/ii
    cp -r ./* $out/share/ii

    mkdir -p $out/share/matugen
    cp -r ${./matugen}/* $out/share/matugen/
    substituteInPlace $out/share/matugen/config.toml --replace-fail 'II_SHARE_DIR' "$out/share"
    cp ${src + "/dots/.config/matugen/templates/colors.json"} $out/share/matugen/colors.json
    cp ${src + "/dots/.config/matugen/templates/wallpaper.txt"} $out/share/matugen/wallpaper.txt

    mkdir -p $out/bin/support

    makeWrapper ${quickshell}/bin/qs $out/bin/support/qs \
      ${wrapperArgs}

    makeWrapper ${quickshell}/bin/qs $out/bin/ii \
      ${wrapperArgs} \
      --add-flags "-p $out/share/ii"
  '';

  meta = with lib; {
    description = "A desktop shell for Hyprland built on Quickshell by end-4";
    homepage = "https://ii.clsty.link/en/";
    license = licenses.gpl3Only;
    mainProgram = "ii";
  };
}
