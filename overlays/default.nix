{
  inputs,
  outputs,
}: {
  additions = final: prev: import ../packages (inputs // {pkgs = final;});

  themes = final: prev: {chromaThemes = import ../themes {pkgs = final;};};

  # Inspired by github.com/Misterio77/nix-config:
  # For every flake input, aliases 'pkgs.inputs.${flake}' to
  # 'inputs.${flake}.packages.${pkgs.system}' or
  # 'inputs.${flake}.legacyPackages.${pkgs.system}',
  # and also define 'pkgs.inputs.${flake}' as the default package
  flake-inputs = final: _: {
    inputs =
      builtins.mapAttrs (
        _: flake: let
          # The order of packages and legacyPackages is important:
          # nix-index-database, for example, exports most packages only in
          # packages, but ont legacyPackages
          packages = (flake.packages or flake.legacyPackages or {}).${final.system} or {};
        in
          if packages ? default
          then packages.default // packages
          else packages
      )
      inputs;
  };
}
