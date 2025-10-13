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
    rev = "02192368d2c5d99fff0cc819a91f9388c4be3902";
    hash = "sha256-if9KBD4wKnEDZTJbF5sm5bKUW44Gm4pBOuR8kepArf8=";
  };

  # TODO: include fonts as well?
  sharePaths = [
    bibata-cursors
    oneUiIcons
  ];

  runtimeDependencies = packages ++ [pythonEnv];

in stdenv.mkDerivation {
  name = "illogical-impulse";
  src = src + "/.config/quickshell/ii";

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
  ];

  prePatch = ''
    cp -r ${src}/.config/quickshell/translations ./translations

    substituteInPlace 'Translation.qml' --replace 'Qt.resolvedUrl(Directories.config + "/quickshell/translations/")' "\"$out/share/ii/translations/\""
    (
      shopt -s globstar
      for file in **/*.py; do
        substituteInPlace "$file" --replace '#!/usr/bin/env -S\_/bin/sh\_-c\_"source\_\$(eval\_echo\_\$ILLOGICAL_IMPULSE_VIRTUAL_ENV)/bin/activate&&exec\_python\_-E\_"\$0"\_"\$@""' "#!${pythonEnv}/bin/python"
      done
    )
  '';

  dontConfigure = true;
  dontBuild = true;

  propagatedBuildInputs = runtimeDependencies;

  installPhase = ''
    mkdir -p $out/share/ii
    cp -r ./* $out/share/ii

    makeWrapper ${quickshell}/bin/qs $out/bin/ii \
      --set FONTCONFIG_FILE ${fontConfig} \
      --set XDG_DATA_DIRS "${lib.makeSearchPath "share" sharePaths}:\$XDG_DATA_DIRS" \
      --set ILLOGICAL_IMPULSE_VIRTUAL_ENV ${pythonEnv.fakeVenv} \
      --prefix PATH : ${lib.makeBinPath runtimeDependencies} \
      --add-flags "-p $out/share/ii"
  '';

  meta = with lib; {
    description = "A desktop shell for Hyprland built on QuickShell by end-4";
    homepage = "https://ii.clsty.link/en/";
    license = licenses.gpl3Only;
    mainProgram = "ii";
  };
}