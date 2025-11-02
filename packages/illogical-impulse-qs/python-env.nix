{
  python,
  writeTextFile,
}: let
  pythonEnv = python.withPackages (ps: with ps; [
    build
    pillow
    setuptools-scm
    pywayland
    psutil
    kde-material-you-colors
    materialyoucolor
    libsass
    material-color-utilities
    setproctitle
    click
    loguru
    pycairo
    pygobject3
    tqdm
    numpy
    opencv4
  ]);

  fakeVenv = writeTextFile {
    name = "illogical-impulse-venv";
    text = ''
      VENV_PATH_BAK=$PATH
      export PATH=${pythonEnv}/bin:$PATH

      deactivate () {
        export PATH=$VENV_PATH_BAK
        unset VENV_PATH_BAK
        unset -f deactivate
      }
    '';
    executable = true;
    destination = "/bin/activate";
  };
in pythonEnv // { inherit fakeVenv; }