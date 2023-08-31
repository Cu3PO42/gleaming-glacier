{
  config,
  lib,
  ...
}:
with lib; let
  features = map (splitString "/") config.copper.features;

  enableOrStep = v: let
    empty = partition (e: length e == 0) v;
    base =
      if length empty.right > 0
      then {enable = true;}
      else {};
  in
    base // step empty.wrong;

  step = paths: let
    grouped = mapAttrs (_: map tail) (groupBy head paths);
  in
    mapAttrs (_: enableOrStep) grouped;
in {
  options = {
    copper.features = mkOption {
      type = with types; listOf str;
      default = [];
      example = ["cli" "rust" "fish"];
      description = ''
        This is simply a convenience option to enable a number of features
        from Copper's config. For every element `mod` that is inculded here,
        the option `copper.features.${mod}.enable = true`; will be set.
      '';
    };
  };

  config = {
    copper.feature = step features;
  };
}
