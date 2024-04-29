{
  pkgs,
  _1password,
  lib,
  ...
}: (pkgs.writeShellScriptBin "op" ''
  if [ -n "$OP_BINARY" ] && command -v "$OP_BINARY" >/dev/null; then
    exec "$OP_BINARY" "$@"
  fi

  if [ -n "$WSL_DISTRO_NAME" ] && command -v op.exe >/dev/null; then
    exec op.exe "$@"
  fi

  PATH="$(echo "$PATH" | tr ":" "\n" | grep -v "$(dirname "$0")" | tr "\n" ":")"
  if command -v op >/dev/null; then
    exec op "$@"
  fi

  exec ${_1password}/bin/op "$@"
'') // {
  meta = with lib; {
    description = "Forward 1Password CLI commands to the best available implementation.";
    homepage = "https://github.com/Cu3PO42/gleaming-glacier";
    license = licenses.gpl3Plus;
    maintainers = ["Cu3PO42"];
  };
}