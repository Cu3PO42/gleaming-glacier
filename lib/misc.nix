{nixpkgs, ...}: {
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
}