{nixpkgs, ...} @ inputs:
rec {
  mapAttrsNonNull =
    # A function, given an attribute's name and value, returns a new `nameValuePair`.
    f:
    # Attribute set to map over.
    set:
      with nixpkgs.lib;
        listToAttrs (filter ({
          name,
          value,
        }:
          value != null) (map (attr: f attr set.${attr}) (attrNames set)));

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
        loadedDirs = concatMap (next: impl "${dir}/${next.name}" "${prefix}${next.name}/") res.wrong;
      in
        loadedFiles ++ loadedDirs;

      files = impl dir "";
      nnFiles = filter (v: v.value != null) files;
    in
      listToAttrs nnFiles;
}
// (import ./modules.nix inputs)
