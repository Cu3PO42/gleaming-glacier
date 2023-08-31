{...}: {
  security.pam.enableSudoTouchIdAuth = true;
  programs.nix-index.enable = true;
}
