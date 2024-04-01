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

  inherit (origin.self.lib.keybinds dispatchOption) keybindOptions collectSubmaps serializeMapInfo;

  maestroctl = "${config.programs.maestro.package}/bin/maestro";

  renderKey = key: let
    actualKey = key.key;
    modifiers = attrNames (filterAttrs (name: value: value) key.modifiers);
  in "${concatStringsSep " " modifiers},${actualKey}";

  renderDispatch = action: "${action.type},${action.arg}";

  renderMapName = name: if name == "$root" then "reset" else name;
  renderMaestroSubmapActivation = name: "exec,${maestroctl} ${if name == "$root" then "exit" else ''activate "${name}"''}";

  renderBind = bind: let
    mods = (optionalString bind.global "t") + (optionalString bind.passthrough "n") + (optionalString bind.repeat "e") + (optionalString bind.activeWhileLocked "l");
    bindPrefix = "bind${mods}=${renderKey bind.key},";

    maestroSubmap = optionalString cfg.maestroIntegration "${bindPrefix}${renderMaestroSubmapActivation bind.submap.id}\n";
    submap = "submap,${bind.submap.id}";

    dispatch = renderDispatch bind.dispatch;
    maestroUse = optionalString cfg.maestroIntegration "\n${bindPrefix}exec,${maestroctl} ${if bind.remain then "use" else "exit"}";
    reset = optionalString (!bind.remain) "\n${bindPrefix}submap,reset";

  in if bind.dispatch != null then
    "${bindPrefix}${dispatch}${maestroUse}${reset}"
  else
    "${maestroSubmap}${bindPrefix}${submap}";

  renderSubmap = submap: let
    parentKey = renderKey cfg.submapSettings.parentMapKey;
    exitKey = renderKey cfg.submapSettings.exitKey;
  in ''
    submap=${renderMapName submap.id}
    ${concatMapStringsSep "\n" renderBind (filter (b: b.enabled) (attrValues submap.binds))}
    ${optionalString (submap.id != "$root" && cfg.maestroIntegration) ''
      bind=${parentKey},${renderMaestroSubmapActivation submap.parentId}
      bind=${exitKey},exec,${maestroctl} exit
    ''}
    ${optionalString (submap.id != "$root") ''
      bind=${parentKey},submap,${renderMapName submap.parentId}
      bind=${exitKey},submap,reset
      bind=,catchall,exec,true
    ''}
    submap=reset
  '';
  keybindSettings = concatMapStringsSep "\n" renderSubmap (collectSubmaps cfg.binds);
in {
  options = {
    wayland.windowManager.hyprland.keybinds = keybindOptions // {
      maestroIntegration = mkEnableOption "Hyprland maestro integration" // { default = true; };
    };
  };

  config = {
    wayland.windowManager.hyprland.extraConfig = "source = ${pkgs.writeText "hyprland-keybinds.conf" keybindSettings}";

    programs.maestro = mkIf cfg.maestroIntegration (let
      agsBin = "${config.programs.ags.finalPackage}/bin/ags -b argyrodite";
      ifAgsEnabled = optionalString config.copper.feature.nixos.argyrodite.enable;
      maestroJs = ''(await import('file://${config.xdg.configHome}/argyrodite/maestro.js'))'';
      keymapJson = pkgs.writeText "keybind-info.json" (serializeMapInfo cfg.binds);
    in {
      enable = true;
      cancelKeymapCommand = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl submap reset";
      helpCommand = ifAgsEnabled ''${agsBin} --run-js "${maestroJs}.showHelp('${keymapJson}', '$KEYMAP')"'';
      cancelHelpCommand = ifAgsEnabled ''${agsBin} --run-js "${maestroJs}.closeHelp()"'';
      keymapTimeout = cfg.submapSettings.timeout;
      helpTimeout = cfg.submapSettings.helpTimeout;
    });
  };
}
