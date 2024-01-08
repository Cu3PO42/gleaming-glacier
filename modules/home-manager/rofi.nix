{config, lib, ...}: with lib; let
  # TODO: all of this should be upstreamed
  # This is almost entirly code from HM's upstream Rofi module.
  # It is copied here so that we can add a single option before it is upstreamd.
  cfg = config.programs.rofi;

  themeName = if (cfg.theme == null) then
    null
  else if (isString cfg.theme) then
    cfg.theme
  else if (isAttrs cfg.theme) then
    "custom"
  else
    removeSuffix ".rasi" (baseNameOf cfg.theme);

    mkValueString = value:
    if isBool value then
      if value then "true" else "false"
    else if isInt value then
      toString value
    else if (value._type or "") == "literal" then
      value.value
    else if isString value then
      ''"${value}"''
    else if isList value then
      "[ ${strings.concatStringsSep "," (map mkValueString value)} ]"
    else
      abort "Unhandled value type ${builtins.typeOf value}";

  mkKeyValue = { sep ? ": ", end ? ";" }:
    name: value:
    "${name}${sep}${mkValueString value}${end}";

  mkRasiSection = name: value:
    if isAttrs value then
      let
        toRasiKeyValue = generators.toKeyValue { mkKeyValue = mkKeyValue { }; };
        # Remove null values so the resulting config does not have empty lines
        configStr = toRasiKeyValue (filterAttrs (_: v: v != null) value);
      in ''
        ${name} {
        ${configStr}}
      ''
    else
      (mkKeyValue {
        sep = " ";
        end = "";
      } name value) + "\n";

  toRasi = attrs:
    concatStringsSep "\n" (concatMap (mapAttrsToList mkRasiSection) [
      (filterAttrs (n: _: n == "@theme") attrs)
      (filterAttrs (n: _: n == "@import") attrs)
      (removeAttrs attrs [ "@theme" "@import" ])
    ]);

  locationsMap = {
    center = 0;
    top-left = 1;
    top = 2;
    top-right = 3;
    right = 4;
    bottom-right = 5;
    bottom = 6;
    bottom-left = 7;
    left = 8;
  };
in {
  options = {
    programs.rofi.imports = mkOption {
      type = with types; listOf str;
      default = [];
      example = [''''${config.xdg.configHome}/rofi/my.config.rasi''];
      description = ''
        Additional configuration files that should be imported into the
        overall config.
      '';
    };
  };

  config = {
    home.file."${cfg.configPath}".text = mkForce (toRasi {
      configuration = ({
        font = cfg.font;
        terminal = cfg.terminal;
        cycle = cfg.cycle;
        location = (getAttr cfg.location locationsMap);
        xoffset = cfg.xoffset;
        yoffset = cfg.yoffset;
      } // cfg.extraConfig);
      # @theme must go after configuration but attrs are output in alphabetical order ('@' first)
    }
    # Theme must come before @import for reasons I'm not entirely clear about.
    # However, having it later results in a 'Failed to load theme' error.
    + (optionalString (themeName != null) (toRasi { "@theme" = themeName; }))
    + concatMapStrings (i: toRasi { "@import" = i; }) cfg.imports);

  };
}
