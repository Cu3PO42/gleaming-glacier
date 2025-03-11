{...}: {
  security.pam.services.sudo_local.touchIdAuth = true;
  programs.nix-index.enable = true;
}
