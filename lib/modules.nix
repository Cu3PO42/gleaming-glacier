{nixpkgs, ...}: rec {
  mkFeatureModule = {
    name,
    cfg,
    description ? "",
    prefix,
  }: let
    inherit (nixpkgs) lib;
    path = lib.splitString "." name;
    addCfgArgs = f: lib.setFunctionArgs f (lib.functionArgs cfg // lib.functionArgs f);
  in
    addCfgArgs ({
        config,
        lib,
        ...
      } @ opts: let
        enable = (lib.attrByPath path {} config.${prefix}.feature).enable or false;
        baseConfig = cfg opts;
        hasOptions = baseConfig ? featureOptions;
        options =
          if hasOptions
          then baseConfig.featureOptions
          else {};
        modCfg =
          if hasOptions
          then baseConfig.config
          else builtins.removeAttrs baseConfig ["imports"];
        imports = baseConfig.imports or [];
      in {
        # We would like this to be an optional import activated only when
        # enable is true. However, that leads to an infinite recursion error:
        # It might be that only the imported module sets the relevant enable
        # option and there is no way to pinky promise that it won't.
        inherit imports;

        options = {
          ${prefix}.feature = lib.setAttrByPath path ({
              enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                example = true;
                description = ''
                  Enable the feature module `${name}` with the description:

                  ${description}
                '';
              };
            }
            // options);
        };
        config = lib.mkIf enable modCfg;
      });

  injectArgs = args: f: let
    inherit (nixpkgs) lib;
    fArgs = lib.functionArgs f;
    remainingArgs = builtins.removeAttrs fArgs (builtins.attrNames args);
    requiredExtraArgs = builtins.intersectAttrs fArgs args;
    newFun = opts: f (opts // requiredExtraArgs);
  in
    lib.setFunctionArgs newFun remainingArgs;

  injectArgsOpt = args: module: if nixpkgs.lib.isFunction module then injectArgs args module else module;

  importInjectArgs = args: path: nixpkgs.lib.setDefaultModuleLocation path (injectArgsOpt args (import path));
}
