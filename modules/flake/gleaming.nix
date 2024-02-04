{lib, ...}: with lib; {
  options = {
    gleaming.basename = mkOption {
      type = types.str;
      example = "copper";
      description = ''
        The prefix that will be used for functionality customized to the
        invoking Flake. This affects, for example, the generated overlays, as
        well as the feature system.
      '';
    };

    gleaming.basepath = mkOption {
      type = types.path;
      example = literalExpression "./.";
      description = "The base path of the Flake from which to load all elmements.";
    };
  };
}