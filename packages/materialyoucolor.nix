{
  fetchPypi,
  python3Packages,
  lib,
  ...
}: let in python3Packages.buildPythonPackage rec {
  pname = "materialyoucolor";
  version = "2.0.9";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-J35//h3tWn20f5ej6OXaw4NKnxung9q7m0E4Zf9PUw4=";
  };

  build-system = with python3Packages; [build installer wheel];
  # Tests are currently broken.
  doCheck = false;

  dependencies = with python3Packages; [
    pillow
  ];

  nativeCheckInputs = with python3Packages; [
    pip
    tox
  ];

  #propagatedBuildInputs = with python3Packages; [setuptools];

  meta = {
    homepage = "https://github.com/T-Dynamos/materialyoucolor-python";
    description = "Material You color algorithms for python!";
    license = lib.licenses.mit;
  };
}