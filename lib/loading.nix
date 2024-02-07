{nixpkgs, home-manager, ...}@inputs: let
  inherit (import ./modules.nix inputs) mkFeatureModule injectArgs importInjectArgs;
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
  
  importIfExists = path: nixpkgs.lib.mkIf (builtins.pathExists path) (import path);
  importIfExistsApply = path: args: nixpkgs.lib.mkIf (builtins.pathExists path) (import path args);

  loadPackages' = path: pkgs: extra: loadDir path ({path, ...}: pkgs.callPackage path extra);

  loadPackages = lib: system: path: pkgs: extra: lib.filterAttrs (_: lib.meta.availableOn {inherit system;}) (
    loadPackages' path pkgs extra
  );

  loadApps = base: pkgs: loadDir (base + "/apps") ({path, ...}: {
    type = "app";
    program = pkgs.lib.getExe (pkgs.callPackage path {inherit inputs;});
  });

  loadModules = {
    injectionArgs,
    basename,
    basepath,
  }: kind:
      loadDirRec (basepath + "/modules/common") ({path, ...}: importInjectArgs injectionArgs path)
      // loadDirRec (basepath + "/modules/${kind}") ({path, ...}: importInjectArgs injectionArgs path)
      // nixpkgs.lib.mapAttrs' (name: value: {
        name = "feature/${name}";
        inherit value;
      }) (loadDirRec (basepath + "/features/${kind}") (
        {
          name,
          path,
          ...
        }:
          nixpkgs.lib.setDefaultModuleLocation path (injectArgs injectionArgs (mkFeatureModule {
            name = builtins.replaceStrings ["/"] ["."] name;
            cfg = import path;
            prefix = basename;
          }))
      ));

    loadSystems = constructor: {
      modules,
      specialArgs,
      dir,
    }:
      loadDir dir ({
        path,
        name,
        ...
      }: let
        modules' =
          [
            (import path)
            ({lib, ...}: {
              networking.hostName = lib.mkOverride 999 (lib.removeSuffix ".nix" name);
            })
          ]
          ++ modules;
      in
        constructor {
          modules = modules';
          inherit specialArgs;
        });

  loadHome = {
    modules,
    specialArgs,
    dir,
  }:
    loadDir dir ({
      path,
      name,
      ...
    }: let
      user = import path;
      username = builtins.elemAt (nixpkgs.lib.splitString "@" name) 0;
      modules' =
        modules
        ++ [
          ({lib, ...}: {
            home.username = lib.mkDefault username;
          })
        ]
        ++ user.modules or [];
    in
      home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${user.system};
        modules = modules';
        extraSpecialArgs = specialArgs;
      });
}