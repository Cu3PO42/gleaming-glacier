{
  pkgs,
  _1password,
  ...
}: let
  op-wsl-proxy = pkgs.writeShellScriptBin "op" ''
    if [ -n "$WSL_DISTRO_NAME" ] && command -v op.exe >/dev/null; then
      exec op.exe $@
    fi

    exec ${_1password}/bin/op $@
  '';
in
  if pkgs.system == "x86_64-linux"
  then op-wsl-proxy
  else _1password
