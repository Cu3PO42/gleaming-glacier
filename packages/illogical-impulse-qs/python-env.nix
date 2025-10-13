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
      export PATH=${pythonEnv}/bin:$PATH
    '';
    executable = true;
    destination = "/bin/activate";
  };
in pythonEnv // { inherit fakeVenv; }