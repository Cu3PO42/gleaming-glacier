{
  python3,
  dart-sass,
  gtksourceview3,
  webp-pixbuf-loader,
  google-fonts,

  stdenvNoCC,
  fetchFromGitHub,
  writeShellApplication,
  writeScriptBin,
  makeWrapper,

  self,
  pkgs,
  inputs,
  lib,
  ...
}: with lib; let
  oneUiIcons = stdenvNoCC.mkDerivation {
    name = "oneui-icons-4";
    src = fetchFromGitHub {
      owner = "end-4";
      repo = "OneUI4-Icons";
      rev = "9ba21908f6e4a8f7c90fbbeb7c85f4975a4d4eb6";
      hash = "sha256-f5t7VGPmD+CjZyWmhTtuhQjV87hCkKSCBksJzFa1x1Y";
      fetchSubmodules = true;
    };
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/icons
      mv OneUI $out/share/icons
      mv OneUI-dark $out/share/icons
      mv OneUI-light $out/share/icons
    '';
  };

  extraFonts = google-fonts.override {
    fonts = [
      "Gabarito"
      "Readex Pro"
    ];
  };

  # TODO: disable color generation script / integrate with chroma or something
  dots = fetchFromGitHub {
    owner = "Cu3PO42";
    repo = "end-4-dots-hyprland";
    rev = "d52578c7c4278656f25643f4d2b7c4a022507eb5";
    hash = "sha256-K7iG+6+6tWThcKDSTdJHRD911UYjBL5wyLIFdWTZX2E=";
  };
  # Note: the main 'interesting' folder is the .config one
  # At the top-level, there is a .local/bin folder with additional binaries
  # that are used at most in Hyprland keybinds.
  # There is also various installation scripts and text files we do not use.
  # Finally, there are themes for gnome-text-editor, which we could put into a
  # derivation. But don't really care about at the moment.
  # Inside the .config folder, there are configs for a multitude of programs.
  # We are interested primarily in the ags config, but it may implicitly rely
  # on some other configurations. For example: it requires Hyprland shaders
  # configured.

  agsConfig = stdenvNoCC.mkDerivation {
    name = "illogical-impulse";
    src = dots + "/.config/ags";

    buildInputs = [
      pythonEnv
    ];

    nativeBuildInputs = [makeWrapper];

    patchPhase = ''
      # The config uses .cache/ags as its cache folder, and ~/.local/state/ags
      # as its state folder, but we'd rather use ones dedicated to this config.
      # Unfortunately, this means patching all ways in which they are
      # referenced.
      (
        shopt -s globstar
        for file in **/*.{js,sh}; do
          substituteInPlace "$file" \
            --replace-quiet '$XDG_CACHE_HOME/ags' "$XDG_CACHE_HOME/illogical-impulse" \
            --replace-quiet 'get_user_cache_dir()}/ags' 'get_user_cache_dir()}/illogical-impulse' \
            --replace-quiet 'USER_CACHE_DIR}/ags' 'USER_CACHE_DIR}/illogical-impulse' \
            --replace-quiet '$XDG_STATE_HOME/ags' "$XDG_STATE_HOME/illogical-impulse" \
            --replace-quiet 'get_user_state_dir()}/ags' 'get_user_state_dir()}/illogical-impulse'
        done
      )
    '';

    installPhase = ''
      runHook preInstall

      # Our config does not reside in ~/.config/ags, but in the derivation we
      # are just creating.
      (
        shopt -s globstar
        for file in **/*.js; do
          substituteInPlace "$file" --replace-quiet "App.configDir" "\"$out\""
        done

        for file in ./scripts/**/*.sh; do
          substituteInPlace "$file" \
            --replace-quiet 'CONFIG_DIR="$XDG_CONFIG_HOME/ags"' "CONFIG_DIR=$out"
        done
      )

      mkdir $out
      mv ./* $out

      runHook postInstall
    '';

    fixupPhase = ''
      # Make all included scripts runnable even when not started from an AGS
      # context.
      (
        shopt -s globstar
        for file in $out/scripts/**/*.{sh,py}; do
          echo "$file"
        done
      ) | while read -r file; do
        wrapProgram "$file" --set PATH ${lib.makeBinPath runtimeDeps}
      done
    '';
  };

  pythonEnv = python3.withPackages (ps: with ps; [
    pywal
    self.materialyoucolor
    pywayland
    psutil
  ]);

  ags = (inputs.ags.packages.default.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [
      gtksourceview3
      webp-pixbuf-loader
    ];
  }));

  agsWrapped = writeScriptBin "ags" ''
    exec ${ags}/bin/ags -b illogical-impulse "$@"
  '';

  sharePaths = with pkgs; [
    jetbrains-mono
    material-symbols
    nerdfonts
    rubik
    bibata-cursors
    extraFonts
  ];

  runtimeDeps = with pkgs; [
    coreutils
    bash
    hyprland
    agsWrapped
    dart-sass
    swappy
    wf-recorder
    grim
    tesseract4
    slurp
    wl-clipboard
    hyprpicker
    upower
    yad
    ydotool
    pavucontrol
    brightnessctl
    wlsunset
    pythonEnv
    gojq
    gnome.gnome-system-monitor
  ];

in (writeShellApplication {
  name = "ags-end-4";
  runtimeInputs = runtimeDeps;

  text = ''
    export XDG_DATA_DIRS="${makeSearchPath "share" (sharePaths ++ [oneUiIcons])}:$XDG_DATA_DIRS"
    exec ags -c "${agsConfig}/config.js"
  '';
}).overrideAttrs (old: {
  propagatedUserEnvPkgs = sharePaths;
})