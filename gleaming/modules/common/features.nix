{
  config,
  lib,
  gleaming,
  ...
}:
with lib; let
  features = map (splitString "/") config.${gleaming.basename}.features;

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
    ${gleaming.basename}.features = mkOption {
      type = with types; listOf str;
      default = [];
      example = ["cli" "rust" "fish"];
      description = ''
        This is simply a convenience option to enable a number of features
        from a Gleaming Glacier-based config. For every element `mod` that
        is inculded here, the option
        `${gleaming.basename}.features.''${mod}.enable = true`; will be set.
      '';
    };
  };

  config = {
    ${gleaming.basename}.feature = step features;
  };
}
