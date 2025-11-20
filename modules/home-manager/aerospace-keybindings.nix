{origin, config, lib, copper, pkgs, ...}: with lib; let
  cfg = config.programs.aerospace;
  dispatchOption = mkOption {
    type = with types; either str (listOf str);
    apply = v: if isString v then [ v ] else v;
  };
  inherit (origin.self.lib.keybinds dispatchOption) keybindOptions collectSubmaps serializeMapInfo;

  modNames = {
    "ctrl" = "ctrl";
    "shift" = "shift";
    "alt" = "alt";
    "super" = "cmd";
  };
  maestroctl = "${config.programs.maestro.package}/bin/maestro";
  submapList = collectSubmaps cfg.keybinds.binds;
  mapListToAttrs = f: l: listToAttrs (map f l);
  optionalMaestro = optional cfg.enableMaestroIntegration;
  renderKey = k: (concatMapStrings (mod: "${modNames.${mod}}-") (attrNames (filterAttrs (k: v: v) k.modifiers))) + k.key;
  renderMapName = name: if name == "$root" then "main" else "s" + (replaceStrings [" "] ["-"] name);
  renderBind = bind: if bind.submap != null then ["mode ${renderMapName bind.submap.id}"] ++
    optionalMaestro "exec-and-forget ${maestroctl} activate \"${bind.submap.id}\""
  else bind.dispatch ++
    optional (!bind.remain) "mode main" ++
    optionalMaestro (if bind.remain then "exec-and-forget ${maestroctl} use" else "exec-and-forget ${maestroctl} exit");
  renderSubmapDef = submap: nameValuePair (renderMapName submap.id) ({ binding =
    mapAttrs' (_: bind: nameValuePair (renderKey bind.key) (renderBind bind)) submap.binds // (if submap.parentId != "" then {
      ${renderKey cfg.keybinds.submapSettings.exitKey} = ["mode main"] ++ optionalMaestro "exec-and-forget ${maestroctl} exit";
      ${renderKey cfg.keybinds.submapSettings.parentMapKey} = ["mode ${renderMapName submap.parentId}"] ++ optionalMaestro "exec-and-forget ${maestroctl} activate \"${submap.parentId}\"";
  } else {}); });
in {
  options = {
    programs.aerospace = {
      keybinds = keybindOptions;
      enableKeybindings = mkEnableOption "Aerospace keybindings" // { default = false; };
      enableMaestroIntegration = mkEnableOption "Aerospace maestro integration" // { default = config.programs.aerospace.enableKeybindings; };
    };
  };

  config = mkIf cfg.enableKeybindings {
    programs.aerospace.keybinds.submapSettings = {
      exitKey = lib.mkDefault { key = "esc"; };
      parentMapKey = lib.mkDefault { key = "backspace"; };
    };
    programs.aerospace.userSettings.mode = mapListToAttrs renderSubmapDef submapList;

    programs.maestro = mkIf cfg.enableMaestroIntegration {
      enable = true;
      cancelKeymapCommand = "${getExe config.programs.aerospace.package} mode main";
      helpCommand = "exec ${copper.packages.mac-keybind-helper}/bin/keybind-helper-client show \"$KEYMAP\" ${pkgs.writeText "keybind-info.json" (serializeMapInfo cfg.keybinds.binds)}";
      cancelHelpCommand = "exec ${copper.packages.mac-keybind-helper}/bin/keybind-helper-client hide";
      keymapTimeout = cfg.keybinds.submapSettings.timeout;
      helpTimeout = cfg.keybinds.submapSettings.timeout;
    };
  };
}