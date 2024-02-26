{
  pkgs,
  _1password,
  lib,
  ...
}: let
  op-wsl-proxy = (pkgs.writeShellScriptBin "op" ''
    if [ -n "$WSL_DISTRO_NAME" ] && command -v op.exe >/dev/null; then
      exec op.exe "$@"
    fi

    exec ${_1password}/bin/op "$@"
  '') // {
    meta = with lib; {
      description = "Forward 1Password CLI commands to the Windows 1Password CLI when running in WSL2.";
      homepage = "https://github.com/Cu3PO42/gleaming-glacier";
      license = licenses.gpl3Plus;
      maintainers = ["Cu3PO42"];
    };
  };
in
  if pkgs.system == "x86_64-linux"
  then op-wsl-proxy
  else _1password
