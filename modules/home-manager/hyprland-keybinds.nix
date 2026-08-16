{config, pkgs, lib, origin, copper, ...}: with lib; let
  cfg = config.wayland.windowManager.hyprland.keybinds;

  dispatchOption = mkOption {
    type = types.str;
    example = ''hl.dsp.exec_cmd("kitty")'';
    description = ''
      The Lua dispatcher expression to use for the keybind.
    '';
  };

  inherit (origin.self.lib.keybinds dispatchOption) keybindOptions collectSubmaps serializeMapInfo;

  maestroctl = "${config.programs.maestro.package}/bin/maestro";
  toLua = generators.toLua {};
  luaInline = generators.mkLuaInline;

  renderLuaTable = value: toLua value;
  renderSubmapDispatcher = name: "hl.dsp.submap(${renderLuaTable (if name == "$root" then "reset" else name)})";
  renderMaestroDispatcher = command: "hl.dsp.exec_cmd(${renderLuaTable "${maestroctl} ${command}"})";

  renderKey = key: let
    actualKey = key.key;
    modifiers = attrNames (filterAttrs (name: value: value) key.modifiers);
  in concatStringsSep " + " (map (mod: toUpper mod) modifiers ++ [actualKey]);

  renderComposite = actions:
    if length actions == 1 then head actions else ''
      function()
        ${concatMapStringsSep "\n" (action: "hl.dispatch(${action})") actions}
      end
    '';

  renderBindOptions = bind: (optionalAttrs bind.global { submap_universal = true; }) //
    (optionalAttrs bind.passthrough { non_consuming = true; }) //
    (optionalAttrs bind.repeat { repeating = true; }) //
    (optionalAttrs bind.activeWhileLocked { locked = true; });

  renderLuaBind = key: action: options: {
    _args = [(renderKey key) (luaInline action)] ++ optional (options != {}) options;
  };

  renderBindAction = bind: let
    dispatch = bind.dispatch;
    maestro = optional cfg.maestroIntegration (renderMaestroDispatcher (if bind.remain then "use" else "exit"));
    reset = optional (!bind.remain) (renderSubmapDispatcher "reset");
  in if bind.dispatch != null then
    renderComposite ([dispatch] ++ maestro ++ reset)
  else
    renderComposite (
      optional cfg.maestroIntegration (renderMaestroDispatcher (if bind.submap.id == "$root" then "exit" else ''activate "${bind.submap.id}"''))
      ++ [(renderSubmapDispatcher bind.submap.id)]
    );

  renderBind = bind: renderLuaBind bind.key (renderBindAction bind) (renderBindOptions bind);

  renderNavigationBind = key: actions: renderLuaBind key (renderComposite actions) {};

  renderSubmap = submap: let
    parentBind = optional (cfg.submapSettings.parentMapKey != null) (
      renderNavigationBind cfg.submapSettings.parentMapKey (
        optional cfg.maestroIntegration (renderMaestroDispatcher (if submap.parentId == "$root" then "exit" else ''activate "${submap.parentId}"''))
        ++ [(renderSubmapDispatcher submap.parentId)]
      )
    );
    exitBind = renderNavigationBind cfg.submapSettings.exitKey (
      optional cfg.maestroIntegration (renderMaestroDispatcher "exit")
      ++ [(renderSubmapDispatcher "reset")]
    );
    catchallBind = renderNavigationBind { key = "catchall"; modifiers = {}; } ["hl.dsp.exec_cmd(\"true\")"];
  in nameValuePair submap.id {
    settings.bind = map renderBind (filter (bind: bind.enabled) (attrValues submap.binds)) ++ parentBind ++ [exitBind catchallBind];
  };

  submaps = listToAttrs (map renderSubmap (collectSubmaps cfg.binds));
  submapsWithoutRoot = lib.removeAttrs submaps ["$root"];
in {
  options = {
    wayland.windowManager.hyprland.keybinds = keybindOptions // {
      maestroIntegration = mkEnableOption "Hyprland maestro integration" // { default = true; };
    };
  };

  config = mkIf config.wayland.windowManager.hyprland.enable {
    wayland.windowManager.hyprland = {
      # Render the top-level binds seperately to make sure they don't have navigation attributes.
      settings.bind = map renderBind (filter (bind: bind.enabled) (attrValues cfg.binds.binds));
      submaps = submapsWithoutRoot;
    };

    programs.maestro = mkIf cfg.maestroIntegration (let
      keymapJson = pkgs.writeText "keybind-info.json" (serializeMapInfo cfg.binds);
      maestroQsBin = "${copper.packages.maestro-qs}/bin/maestro-qs-ipc";
    in {
      enable = true;
      cancelKeymapCommand = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl dispatch 'hl.dsp.submap(\"reset\")'";
      helpCommand = "${maestroQsBin} call maestro showHelp ${keymapJson} \"$KEYMAP\"";
      cancelHelpCommand = "${maestroQsBin} call maestro hideHelp";
      keymapTimeout = cfg.submapSettings.timeout;
      helpTimeout = cfg.submapSettings.helpTimeout;
    });
  };
}
