# This integrates a package that is currently sitting in nixpkgs PR #257234
{replaceDependencies, lib, ...}:
lib.warn "replaceDependencies is now included in upstream Nixpkgs, there is no need to rely on my packaged version anymore" replaceDependencies
