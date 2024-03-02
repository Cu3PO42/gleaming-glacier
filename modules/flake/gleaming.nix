{lib, ...}: with lib; {
  options = {
    gleaming.namespace = mkOption {
      type = types.str;
      example = "copper";
      description = ''
        The prefix that will be used for functionality customized to the
        invoking Flake. This affects, for example, the generated overlays, as
        well as the feature system.
      '';
    };

    gleaming.src = mkOption {
      type = types.path;
      example = literalExpression "./.";
      description = "The base path of the Flake from which to load all elmements.";
    };
  };
}