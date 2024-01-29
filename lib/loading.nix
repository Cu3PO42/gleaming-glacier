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
      (filterAttrs (name: typ: (hasSuffix ".nix" name && name != "default.nix") || typ == "directory") (builtins.readDir dir));

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

      files = impl dir "";
      nnFiles = filter (v: v.value != null) files;
    in
      listToAttrs nnFiles;

  loadPackages' = path: pkgs: loadDir path ({path, ...}: pkgs.callPackage path {inherit inputs;});

  loadPackages = path: pkgs: pkgs.lib.filterAttrs (_: pkgs.lib.meta.availableOn pkgs.hostPlatform) (
    loadPackages' path pkgs
  );

  loadModules = specialArgs: base: name:
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