{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options = {
    neo2.enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = mdDoc ''
        Copy the Neo2 keyboard layout to /Library/Keyboard Layouts.
      '';
    };
  };

  config = {
    system.activationScripts.extraActivation.text = mkIf config.neo2.enable ''
      echo "copying Neo layout"
      cp ${./neo.icns} "/Library/Keyboard Layouts/neo.icns"
      cp ${./neo.keylayout} "/Library/Keyboard Layouts/neo.keylayout"
    '';
  };
}
