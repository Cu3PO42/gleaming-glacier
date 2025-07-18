{lib, config, ...}:
with lib; {
  options = {
    defaultUser = mkOption {
      type = types.str;
      example = "johnsmith";
      description = mdDoc ''
        The UNIX user to use for operations that require a concrete user
        account. For example: setting the shell or installing Homebrew.
        The user must exist and is not automatically created.
      '';
    };
  };

  config = {
    system.primaryUser = mkDefault config.defaultUser;
  };
}
