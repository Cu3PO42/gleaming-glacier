{nixpkgs, home-manager, ...}@inputs: let
  inherit (import ./modules.nix inputs) mkFeatureModule injectArgs importInjectArgs;
in rec {
  loadDir = with nixpkgs.lib;
    dir: f: let
      contents = if builtins.pathExists dir then builtins.readDir dir else {};
      contents' = mapAttrsToList (name: value: {
        inherit name;
        typ = value;
      }) contents;
      validImports = filter (e: hasSuffix ".nix" e.name && e.name != "default.nix" || e.typ == "directory") contents';
      imported = map ({name, ...}: {
        name = removeSuffix ".nix" name;
        value = f {
          inherit name;
          path = dir + "/${name}";
        };
      }) validImports;
      nnImported = filter (v: v.value != null) imported;
    in listToAttrs nnImported;

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
    namespace,
    src,
  }: kind:
      loadDirRec (src + "/modules/common") ({path, ...}: importInjectArgs injectionArgs path)
      // loadDirRec (src + "/modules/${kind}") ({path, ...}: importInjectArgs injectionArgs path)
      // nixpkgs.lib.mapAttrs' (name: value: {
        name = "feature/${name}";
        inherit value;
      }) (loadDirRec (src + "/features/${kind}") (
        {
          name,
          path,
          ...
        }:
          nixpkgs.lib.setDefaultModuleLocation path (injectArgs injectionArgs (mkFeatureModule {
            name = builtins.replaceStrings ["/"] ["."] name;
            cfg = import path;
            prefix = namespace;
          }))
      ));

  isNewHost = host: host ? main;

  loadSystems = constructor: {
    modules,
    specialArgs,
    dir,
  }:
    loadDir dir ({
      path,
      name,
      ...
    }: with nixpkgs.lib; let
      entry = import path;
      modules' =
        [
          (
            if isNewHost entry then
              setDefaultModuleLocation path entry.main
            else
              warn "Gleaming Autoload: defining a host via an unwrapped module is deprecated." entry
          )
          ({options, lib, ...}: {
            options.gleaming.autoload = with lib; {
              path = mkOption {
                type = types.str;
                readOnly = true;
                description = "The path at which the module for the host is located.";
              };

              name = mkOption {
                type = types.str;
                readOnly = true;
                description = "The name of the host.";
              };

              entry = mkOption {
                type = types.anything;
                readOnly = true;
                description = "The host definition itself.";
              };
            };

            config.gleaming.autoload = {
              inherit path name;
              entry = if isNewHost entry then entry else { main = entry; };
            };

            config.networking.hostName = lib.mkDefault (lib.removeSuffix ".nix" name);
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
        ++ (if user ? main then [user.main] else [])
        ++ (if user ? modules then nixpkgs.lib.warn user.modules "The modules property for home configurations is deprecated. Please use 'main' instead which accepts a single module." else []);
    in
      home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${user.system};
        modules = modules';
        extraSpecialArgs = specialArgs;
      });

  loadConfig = dir: let
    load = dir: loadDir dir ({path, ...}: let
      def = import path;
    in if isNewHost def then def.copperConfig or {} else {});
  in load (dir + "/darwin") // load (dir + "/nixos");
}