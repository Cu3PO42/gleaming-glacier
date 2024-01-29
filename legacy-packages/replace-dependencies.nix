# This integrates a package that is currently sitting in nixpkgs PR #257234
{callPackage, fetchurl, ...}: callPackage (fetchurl {
  url = "https://raw.githubusercontent.com/alois31/nixpkgs/3700df871b4cf1895de0936cab0f521514a978bb/pkgs/build-support/replace-dependencies.nix";
  hash = "sha256-RVl5yj5sgbblExT+Tgg9rhk/PXtd2So8RQ5VaVJptDo=";
}) {}