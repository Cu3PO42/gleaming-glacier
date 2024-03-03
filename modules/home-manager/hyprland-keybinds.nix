{config, pkgs, lib, origin, ...}: with lib; let
  cfg = config.wayland.windowManager.hyprland.keybinds;

  dispatchOption = mkOption {
    type = with types; either str (submodule ({
      options = {
        type = mkOption {
          type = types.str;
          example = "exec";
          description = ''
            The Hyprland dispatcher to use for the keybind.
          '';
        };

        arg = mkOption {
          type = types.str;
          default = "";
          example = "rofi";
          description = ''
            The arguments passed to the dispatcher.
            This is not checked for validity against the specified dispatcher.
          '';
        };
      };
    }));
    apply = v: if v == null then null else
      if isString v then let
        elems = splitString "," v;
        type = head elems;
        arg = concatStringsSep "," (tail elems);
      in { inherit type arg; } else v;
  };

  inherit (origin.self.lib.keybinds dispatchOption) keybindOptions collectSubmaps;

  renderKey = key: let
    actualKey = key.key;
    modifiers = attrNames (filterAttrs (name: value: value) key.modifiers);
  in "${concatStringsSep " " modifiers},${actualKey}";

  renderDispatch = action: "${action.type},${action.arg}";

  renderMapName = name: if name == "$root" then "reset" else name;

  renderBind = bind: let
    mods = (optionalString bind.global "t") + (optionalString bind.passthrough "n") + (optionalString bind.repeat "e") + (optionalString bind.activeWhileLocked "l");
    dispatch = renderDispatch bind.dispatch;
    submap = "submap,${bind.submap.id}";
    bindPrefix = "bind${mods}=${renderKey bind.key},";
    reset = optionalString (!bind.remain && bind.submap == null) "\n${bindPrefix}submap,reset";
  in "${bindPrefix}${if bind.dispatch != null then dispatch else submap}${reset}";

  renderSubmap = submap: ''
    submap=${renderMapName submap.id}
    ${concatMapStringsSep "\n" renderBind (filter (b: b.enabled) (attrValues submap.binds))}
    ${optionalString (submap.id != "$root") ''
      bind=${renderKey cfg.submapSettings.parentMapKey},submap,${renderMapName submap.parentId}
      bind=${renderKey cfg.submapSettings.exitKey},submap,reset
      bind=,catchall,exec,true
    ''}
    submap=reset
  '';
  keybindSettings = concatMapStringsSep "\n" renderSubmap (collectSubmaps cfg.binds);
in {
  options = {
    wayland.windowManager.hyprland.keybinds = keybindOptions;
  };

  config = {
    wayland.windowManager.hyprland.extraConfig = "source = ${pkgs.writeText "hyprland-keybinds.conf" keybindSettings}";
  };
}
