# This is a direct port of libadwaita-without-adwaita from AUR:
# https://aur.archlinux.org/packages/libadwaita-without-adwaita-git
# The patch is upstreamed here since it seems AUR is missing a reliable way to
# download it without potential of it changing.

{libadwaita, pkgs, ...}: libadwaita.overrideAttrs (prev: final: {
  patchPhase = (prev.pathPhase or "") + "\n" + ''
    ${pkgs.patch}/bin/patch src/adw-style-manager.c < ${./theming_patch.diff}
  '';
  doCheck = false;
})