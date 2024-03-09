{config, lib, pkgs, origin, copper, ...}: with lib; let
  cfg = config.programs.skhd;
  dispatchOption = mkOption {
    type = types.str;
    example = "open-iterm-window";
    description = ''
      The command line to run. It will be executed in the user's $SHELL.
    '';
  };

  inherit (origin.self.lib.keybinds dispatchOption) keybindOptions collectSubmaps serializeMapInfo;

  maestroctl = "${config.programs.maestro.package}/bin/maestro";

  skhdMods = {
    "ctrl" = "ctrl";
    "shift" = "shift";
    "alt" = "lalt";
    "super" = "cmd";
  };
  skhdKeyRewrites = {
    "uparrow" = "up";
    "downarrow" = "down";
    "leftarrow" = "left";
    "rightarrow" = "right";
  };
  renderKey = key: let
    actualKey = let name = toLower key.key; in skhdKeyRewrites.${name} or name;
    modifiers = map (e: skhdMods.${e}) (attrNames (filterAttrs (name: value: value) key.modifiers));
  in "${concatStringsSep " + " modifiers}${optionalString (length modifiers > 0) " - "}${actualKey}";

  # TODO: show warning that activeWhileLocked is not supported? repeat also not supported

  # Mode names in skhd must start with a letter and may only contain letters and underscores.
  renderMapName = name: if name == "$root" then "default" else "m" + replaceStrings [" " "_" "0" "1" "2" "3" "4" "5" "6" "7" "8" "9"] ["_s" "__" "_na" "_nb" "_nc" "_nd" "_ne" "_nf" "_ng" "_nh" "_ni" "_nj"] name;
  submapList = collectSubmaps cfg.keybinds.binds;
  allMapNames = concatMapStringsSep "," (submap: renderMapName submap.id) submapList;
  exitKey = renderKey cfg.keybinds.submapSettings.exitKey;

  renderBind = mode: bind: let
    passthrough = optionalString bind.passthrough "->";
    submap = "; ${renderMapName bind.submap.id}";
    reset = optionalString (!bind.remain) "skhd -k '${exitKey}'; ";
    maestro = optionalString (cfg.maestroIntegration && bind.remain) "${maestroctl} use; ";
    dispatch = ": ${maestro}${reset}${bind.dispatch}";
    modePrefix = if bind.global then allMapNames else renderMapName mode;
  in "${modePrefix} < ${renderKey bind.key} ${passthrough} ${if bind.dispatch != null then dispatch else submap}";

  renderSubmapDef = submap: let
    maestro = optionalString (cfg.maestroIntegration) (": ${maestroctl} " + (if submap.id == "$root" then "exit" else "activate \"${submap.id}\""));
    consume = optionalString (submap.id != "$root") "@";
  in '':: ${renderMapName submap.id} ${consume} ${maestro}'';
  renderSubmap = submap: ''
    ${concatMapStringsSep "\n" (renderBind submap.id) (filter (b: b.enabled) (attrValues submap.binds))}
    ${optionalString (submap.id != "$root") ''
      ${renderMapName submap.id} < ${exitKey} ; default
      ${renderMapName submap.id} < ${renderKey cfg.keybinds.submapSettings.parentMapKey} ; ${renderMapName submap.parentId}
    ''}
  '';
  skhdrc = ''
    ${concatMapStringsSep "\n" renderSubmapDef submapList}

    ${concatMapStringsSep "\n" renderSubmap submapList}
  '';
in {
  options = {
    programs.skhd = {
      enable = mkEnableOption "skhd keybinds";
      maestroIntegration = mkEnableOption "skhd maestro integration" // { default = true; };
      keybinds = keybindOptions;
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."skhd/skhdrc".text = skhdrc;

    programs.maestro = mkIf cfg.maestroIntegration {
      enable = true;
      cancelKeymapCommand = "/run/current-system/sw/bin/skhd -k \"${exitKey}\"";
      helpCommand = "exec ${copper.packages.mac-wm-helpers}/bin/show-keybind-helper ${pkgs.writeText "keybind-info.json" (serializeMapInfo cfg.keybinds.binds)} \"$KEYMAP\"";
      keymapTimeout = cfg.keybinds.submapSettings.timeout;
      helpTimeout = cfg.keybinds.submapSettings.helpTimeout;
    };
  };
}