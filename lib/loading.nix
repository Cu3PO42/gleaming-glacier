{nixpkgs, ...}@inputs: let
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

}