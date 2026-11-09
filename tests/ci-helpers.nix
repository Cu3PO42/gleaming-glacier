{
  lib,
  runCommand,
  python3,
  bash,
  git,
}: let
  src = lib.fileset.toSource {
    root = ../.;
    fileset = lib.fileset.unions [
      (lib.fileset.fileFilter (file: file.hasExt "py" || file.hasExt "sh") ../ci)
      (lib.fileset.fileFilter (file: lib.hasPrefix "test_ci_" file.name && file.hasExt "py") ./.)
    ];
  };
in
  runCommand "ci-helper-tests" {
    nativeBuildInputs = [python3 bash git];
    PYTHONDONTWRITEBYTECODE = "1";
  } ''
    cd ${src}
    python3 -m unittest discover -s tests -p 'test_ci_*.py'
    touch "$out"
  ''
