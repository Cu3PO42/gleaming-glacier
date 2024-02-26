{nixpkgs, ...}@imports: with nixpkgs.lib; dispatchOption: rec {
  inherit (import ./types.nix imports) submoduleWithAssertions;

  keyType = types.submodule ({...}: {
    # TODO: how to handle the differentiation between right and left mods?

    options = let
      mkModOption = mod: mkOption {
        type = types.bool;
        example = true;
        default = false;
        description = ''Whether the ${mod} key needs to be pressed to activate the keybind.'';
      };
    in {
      modifiers = {
        shift = mkModOption "shift";
        ctrl = mkModOption "ctrl";
        alt = mkModOption "alt";
        super = mkModOption "super";
      };

      # TODO: is this sufficiently abstracted? Define which names are valid
      key = mkOption {
        type = types.str;
        example = "a";
        description = ''The key that should trigger the action.'';
      };

      # TODO: keycode as alternative option?
    };

    config = {};
  }) // {
    merge = lib.options.mergeEqualOptions;
  };

  parseKeys = keys: let
    elements = filter (e: e != "") (splitString " " keys);
    actualKey = last elements;
    modifierMap = {
      "ctrl" = "ctrl";
      "alt" = "alt";
      "shift" = "shift";
      "super" = "super";
      "command" = "super";
      "meta" = "super";
      "win" = "super";
    };
    modifiers = listToAttrs (map (e: { name = modifierMap.${toLower e}; value = true; }) (init elements));
  in { inherit modifiers; key = actualKey; };

  keybindType = {prefix, isRoot ? false, remain}: submoduleWithAssertions ({name, config, ...}: {
    options = {
      enabled = mkOption {
        type = types.bool;
        default = true;
        description = ''Whether the keybind should be enabled.'';
      };

      id = mkOption {
        type = types.str;
        readOnly = true;
        description = ''
          Just an identifier for the keybind. Set automatically when it is
          used.
        '';
      };

      key = mkOption {
        type = keyType;
        example = literalExpression ''parseKeys "super a"'';
        description = ''The kind that should trigger the action.'';
      };

      passthrough = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether the keybind should be passed to the active application,
          even if it matches.
        '';
      };

      global = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Whether the keybind should be active even when we are in some submap.
          This setting must only be set for keybinds at the top-level and it
          must not be used with submaps.
        '';
      };

      repeat = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether the keybind should be triggered repeatedly when the key is
          held down.
        '';
      };

      remain = mkOption {
        type = types.bool;
        default = remain;
        description = ''
          Whether the submap should remain active after the keybind is used.
          This setting defaults to the value of the submap's remain setting.
        '';
      };

      activeWhileLocked = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether this keybind should be available even while the screen is
          locked.
        '';
      };

      name = mkOption {
        type = types.str;
        example = "Switch to next Workspace";
        description = ''
          A short-form description of the keybinds action or submap. Will be
          used for the keybind helper menu and keybind search.
        '';
      };

      description = mkOption {
        type = types.str;
        default = "";
        description = ''
          A longer description of the keybinds intent and functionality.
          For submaps this is shown when its helper menu is open.
        '';
      };

      dispatch = dispatchOption // {
        type = types.nullOr dispatchOption.type;
        default = null;
        description = ''
          The action to execute when the keybind is activated. The nature of
          possible actions depends on the context in which this module is used.
          Mutually exclusive with a submap.
        '';
      };

      submap = mkOption {
        type = types.nullOr keymapType;
        default = null;
        description = ''
          The submap to activate when the keybind is hit. Mutually exclusive
          with a dispatch action.
        '';
      };
    };

    config = {
      assertions = [
        {
          assertion = (config.dispatch != null) != (config.submap != null);
          message = "You must define exactly one of dispatch and submap actions.";
        }
        {
          assertion = config.passthrough -> (config.dispatch != null);
          message = "Passthrough can only be set on dispatch actions, not for submap activation";
        }
        {
          assertion = config.global -> isRoot;
          message = "Global keybinds may only be defined on the top-level.";
        }
      ];

      id = "${prefix}_${name}";
      key = mkDefault (parseKeys name);
      submap = mkIf (config.dispatch == null) {
        id = config.id;
        parentId = prefix;
      };
    };
  });

  keymapType = types.submodule ({config, ...}: {
    options = {
      id = mkOption {
        type = types.str;
        description = ''
          An identifier for the current keymap. Must be unique for the current
          application. Determined automatically.
        '';
      };

      parentId = mkOption {
        type = types.nullOr types.str;
        description = ''
          The unique identifier of the parent keymap, i.e. the map containing
          the bind that activated this one.

          If null, this keymap is the global one.
        '';
      };

      remain = mkOption {
        type = types.bool;
        default = false;
        example = true;
        description = ''
          Remain in this submap after using it for the first time.

          This is a default setting for all binds in this submap, but it can be
          overriden on a per-bind basis. A submap with this activated for all
          binds can only be exited through either the exit or parent bind.
        '';
      };

      binds = mkOption {
        type = types.attrsOf (keybindType {prefix = config.id; isRoot = false; inherit (config) remain;});
        default = {};
        description = ''
          All of the keybinds contained in this particular submap.
        '';
      };
    };
  });

  submapOptions = {
    # TODO: catch-all binds? see Hyprland#3405
    infoPopupTimeout = mkOption {
      type = types.ints.unsigned;
      default = 2;
      example = 1;
      description = ''
        After the given amount of seconds, show a helper popup that lists all
        available keybinds.
      '';
    };

    timeout = mkOption {
      type = types.ints.positive;
      default = 5;
      example = 10;
      description = ''
        Number of seconds that any submap should stay active before
        resetting to the global one.

        Note that some implementations may not support this behavior and will
        stay in a submap indefinitely.
      '';
    };

    exitKey = mkOption {
      type = keyType;
      default = { key = "Escape"; };
      description = ''
        The key to hit leave the submap and return to the global one.
      '';
    };

    parentMapKey = mkOption {
      type = types.nullOr keyType;
      default = { key = "BackSpace"; };
      description = ''
        This key will return the user to the parent map, whether it is the
        global one or just another nested one.
      '';
    };
  };

  keybindOptions = {
    submapSettings = submapOptions;
    binds = mkOption {
      type = types.attrsOf (keybindType {prefix = ""; isRoot = true; remain = true;});
      default = {};
      apply = binds: {
        id = "$root";
        remain = true;
        name = "Root";
        description = ''
          The keymap that is active by default.
        '';
        inherit binds;
      };
    };
  };

  collectSubmaps = keymap: let
    binds = attrValues keymap.binds;
    enabledSubmapBinds = filter (bind: bind.enabled && bind.submap != null) binds;
    submaps = concatMap (bind: collectSubmaps bind.submap) enabledSubmapBinds;
  in [keymap] ++ submaps;
}