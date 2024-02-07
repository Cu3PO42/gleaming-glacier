{inputs, getSystemIgnoreWarning, lib, config, ...}: {
  config = {
    flake = {
      overlays = {
        additions = final: prev:
          let
            sys = getSystemIgnoreWarning (prev.stdenv.hostPlatform.system or prev.system);
            # allModuleArgs is injected via flake-parts' withSystem module
            perSys = (sys.allModuleArgs.extendModules {
              modules = [{
                _module.args.pkgs = lib.mkForce prev;
              }];
            }).config;
          in {
            ${config.gleaming.basename} =
              (perSys.packages or {})
              // (perSys.legacyPackages or {})
              // (if perSys ? chromaThemes then { inherit (perSys) chromaThemes; } else {});
          };

        # Inspired by github.com/Misterio77/nix-config:
        # For every flake input, aliases 'pkgs.${basename}-inputs.${flake}' to
        # 'inputs.${flake}.packages.${pkgs.system}' or
        # 'inputs.${flake}.legacyPackages.${pkgs.system}',
        # and also define 'pkgs.inputs.${flake}' as the default package
        flake-inputs = final: _: {
          "${config.gleaming.basename}-inputs" =
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
      };
    };
  };
}