# This module is very much WIP. It is supposed to enable input methods for the
# current user. However, it doesn't work quite right yet. In particular, the
# input selector is not shown and the methods are not always added.
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; {
  options = {
    keyboard-layouts.enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = mdDoc ''
        Whether to enable the management of added keyboard layouts.
      '';
    };

    keyboard-layouts.extraLayouts = mkOption {
      type = types.attrsOf (types.listOf (types.submodule {
        options = {
          name = mkOption {
            type = types.str;
            example = "ABC-QWERTZ";
            description = "The name of the keyboard layout as shown in the Settings app.";
          };

          id = mkOption {
            type = types.int;
            example = 253;
            description = "The internal ID of the keyboard layout. Must match the layout given by the name";
          };
        };
      }));
      default = {};
      example = literalExpression ''{ johnsmith = [{ name = "ABC-QWERTZ"; id = 253; }]; }'';
    };
  };

  config = {
    system.activationScripts.extraActivation.text = mkIf config.keyboard-layouts.enable (mkAfter (concatStringsSep "\n" (mapAttrsToList (user: layouts:
      ''
        LAYOUT_INFO=$(sudo -u ${user} defaults read com.apple.HIToolbox AppleEnabledInputSources | plutil -convert json -o - -)
      ''
      + (concatMapStringsSep "\n" (layout: ''
          if ! ${pkgs.jq}/bin/jq 'any(.[]; ."KeyboardLayout Name" == "${layout.name}")' <<< "$LAYOUT"; then
            sudo -u ${user} defaults write com.apple.HIToolbox AppleEnabledInputSources -array-add '<dict><key>InputSourceKind</key><string>Keyboard Layout</string><key>KeyboardLayout ID</key><integer>${toString layout.id}</integer><key>KeyboardLayout Name</key><string>${layout.name}</string></dict>'
          fi
        '')
        layouts))
    config.keyboard-layouts.extraLayouts)));
  };
}
