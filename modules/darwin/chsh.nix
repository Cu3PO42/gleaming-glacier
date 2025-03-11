{
  config,
  lib,
  pkgs,
  copper,
  ...
}:
with lib; let
  cfg = config.chsh;

  changeUserShell = user: s: let
    shell = normalizeShellPath s;
  in ''
    if [ "$(dscl . -read "/Users/${user}" UserShell | sed 's/UserShell: //')" != "${shell}" ]; then
      sudo chsh -s "${shell}" "${user}"
    fi
  '';

  # The same path normalization as performed by the nix-darwin system/shells module.
  normalizeShellPath = shell:
    if types.shellPackage.check shell
    then "/run/current-system/sw${shell.shellPath}"
    else shell;

  # Shells that are present by default on macOS.
  defaultShells = [
    /bin/bash
    /bin/csh
    /bin/dash
    /bin/ksh
    /bin/sh
    /bin/tcsh
    /bin/zsh
  ];

  # The wrapper waits for /nix to mount and then execs the correct shell for the user
  mkWrapper = users: let
    usersWithNonDefaultShells = lib.filterAttrs (u: shell: !(builtins.elem shell defaultShells)) users;
    usersWithNormalizedShells = lib.mapAttrs (u: normalizeShellPath) usersWithNonDefaultShells;
  in
    # Use callPackage instead of a copper.packages references so this module
    # is usable fully standalone.
    pkgs.callPackage ../../packages/mac-shell-wrapper {users = usersWithNormalizedShells;};

  replaceWithWrapper = shell:
    if types.shellPackage.check shell
    then cfg.wrapperPath
    else shell;

  changeUserShellWithWrapper = user: shell: changeUserShell user (replaceWithWrapper shell);
in {
  options = {
    chsh.users = mkOption {
      type = types.attrsOf (types.either types.shellPackage types.path);
      default = {};
      example = literalExpression "{ johnsmith = pkgs.fish; }";
      description = ''
        Change the login shell for any user present on the system.
        If given a package, it is automatically added to /etc/shells,
        otherwise it must be one of the default shells present there or
        added to `environment.shells`.
      '';
    };

    chsh.useWrapper = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        If enabled, the user's shell will not be set directly to the specified
        shell, but rather to a thin wrapper provided by the module. This
        wrapper will wait for `/nix` to mount before `exec`ing the real shell.
        You should use this if and only if you use FileVault to encrypt your
        disk. In such a situation, applications can start before `/nix/ is
        mounted, at which time the shell will not be available.

        The wrapping only applies to shells installed via Nix.
      '';
    };

    chsh.wrapperPath = mkOption {
      type = types.path;
      default = "/usr/local/bin/shell-wrapper";
      example = "/usr/local/bin/shell-wrapper";
      description = ''
        The path at which to install the wrapper. It should be a user-independent
        path on the data partition.
      '';
    };
  };

  config = {
    assertions =
      mapAttrsToList (user: shell: {
        assertion = types.shellPackage.check shell || builtins.elem shell defaultShells || builtins.elem config.environment.shells;
        message = "The shell configured for ${user} is not available.";
      })
      cfg.users;

    environment.shells =
      if cfg.useWrapper
      then [cfg.wrapperPath]
      else filter types.shellPackage.check (attrValues config.chsh.users);

    system.activationScripts.postActivation.text =
      optionalString cfg.useWrapper ''
        mkdir -p "$(dirname "${cfg.wrapperPath}")"
        cp "${mkWrapper cfg.users}/bin/shell-wrapper" "${cfg.wrapperPath}"
        chown root:wheel "${cfg.wrapperPath}"
        chmod 0755 "${cfg.wrapperPath}"
      ''
      + concatStringsSep "\n" (mapAttrsToList changeUserShellWithWrapper cfg.users);
  };
}
