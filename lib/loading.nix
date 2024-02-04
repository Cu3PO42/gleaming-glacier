{nixpkgs, home-manager, ...}@inputs: let
  inherit (import ./modules.nix inputs) mkFeatureModule injectArgs;
in rec {
  loadDir = with nixpkgs.lib;
    dir: f:
      mapAttrs' (name: _: {
        name = removeSuffix ".nix" name;
        value = f {
          inherit name;
          path = dir + "/${name}";
        };
      })
      (filterAttrs (name: typ: (hasSuffix ".nix" name && name != "default.nix") || typ == "directory") (if builtins.pathExists dir then builtins.readDir dir else {}));

  loadDirRec = dir: f:
    with nixpkgs.lib; let
      impl = dir: prefix: let
        elements = mapAttrsToList (name: value: {
          inherit name;
          typ = value;
        }) (builtins.readDir dir);
        files = filter (v: v.typ == "regular" && (hasSuffix ".nix" v.name) && v.name != "default.nix") elements;
        directories = filter (v: v.typ == "directory") elements;
        res = partition (d: builtins.pathExists "${dir}/${d.name}/default.nix") directories;

        loadedFiles = map (file: let
          name = "${prefix}${removeSuffix ".nix" file.name}";
        in {
          inherit name;
          value = f {
            inherit name;
            path = dir + "/${file.name}";
          };
        }) (files ++ res.right);
        loadedDirs = concatMap (next: impl (dir + "/${next.name}") "${prefix}${next.name}/") res.wrong;
      in
        loadedFiles ++ loadedDirs;

      files = if builtins.pathExists dir then impl dir "" else [];
      nnFiles = filter (v: v.value != null) files;
    in
      listToAttrs nnFiles;

  loadPackages' = path: pkgs: extra: loadDir path ({path, ...}: pkgs.callPackage path extra);

  loadPackages = lib: system: path: pkgs: extra: lib.filterAttrs (_: lib.meta.availableOn {inherit system;}) (
    loadPackages' path pkgs extra
  );

  loadModules = specialArgs: prefix: base: name:
    nixpkgs.lib.mapAttrs (_: injectArgs specialArgs) (
      loadDirRec (base + "/modules/common") ({path, ...}: import path)
      // loadDirRec (base + "/modules/${name}") ({path, ...}: import path)
      // nixpkgs.lib.mapAttrs' (name: value: {
        name = "feature/${name}";
        inherit value;
      }) (loadDirRec (base + "/features/${name}") (
        {
          name,
          path,
          ...
        }:
          mkFeatureModule {
            name = builtins.replaceStrings ["/"] ["."] name;
            cfg = import path;
            inherit prefix;
          }
      ))
    );

    loadSystems = {
      constructor,
      copperModules,
      specialArgs_,
    }: {
      dir,
      extraModules ? [],
      withCopperModules ? true,
      specialArgs ? specialArgs_,
    }:
      loadDir dir ({
        path,
        name,
        ...
      }: let
        modules =
          [
            (import path)
            ({lib, ...}: {
              networking.hostName = lib.mkOverride 999 (lib.removeSuffix ".nix" name);
            })
          ]
          ++ nixpkgs.lib.optionals withCopperModules (copperModules
            ++ [
              ({lib, ...}: {
                copper.feature.base.enable = lib.mkDefault true;
              })
            ])
          ++ extraModules;
      in
        constructor {
          inherit modules specialArgs;
        });

  loadHome = {
    specialArgs_,
    copperModules
  }: {
    dir,
    extraModules ? [],
    withCopperModules ? true,
    specialArgs ? specialArgs_,
  }:
    loadDir dir ({
      path,
      name,
      ...
    }: let
      user = import path;
      username = builtins.elemAt (nixpkgs.lib.splitString "@" name) 0;
      modules =
        (nixpkgs.lib.optionals withCopperModules (copperModules
          ++ [
            ({lib, ...}: {
              copper.feature.standaloneBase.enable = lib.mkDefault true;
            })
          ]))
        ++ extraModules
        ++ [
          ({lib, ...}: {
            home.username = lib.mkDefault username;
          })
        ]
        ++ user.modules or [];
    in
      home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${user.system};
        inherit modules;
        extraSpecialArgs = specialArgs;
      });
}