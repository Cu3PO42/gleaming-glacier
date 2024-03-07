{nixpkgs, ...}: with nixpkgs.lib; let
  orEmpty = val:
    if val == null
    then ""
    else val;
in {
  buildVars = cfg: ''
    TARGET="${cfg.target}"
    ${optionalString (cfg.targetUser != null) ''DEFAULT_TARGET_USER="${cfg.targetUser}"''}
    DISK_ENCRYPTION_KEY="${orEmpty cfg.diskEncryptionKey}"
    INITRD_PUBLIC_KEY="${orEmpty cfg.initrdPublicKey}"
    HOST_KEY="${orEmpty cfg.hostKey}"
    HOST_KEY_LOCATION="${cfg.hostKeyLocation}"
    ${optionalString (cfg.opAccount != null) "export OP_ACCOUNT='${cfg.opAccount}'"}
    NIXOS_ANYWHERE_ARGS=(${escapeShellArgs cfg.extraNixosAnywhereArgs})
  '';
}