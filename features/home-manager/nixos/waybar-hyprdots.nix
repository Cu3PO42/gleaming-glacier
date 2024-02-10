{
  config,
  lib,
  pkgs,
  copper,
  ...
}: {
  copper.feature.nixos.waybar.enable = true;

  home.activation.waybarConfigGeneration = lib.hm.dag.entryBetween ["reloadSystemd"] ["linkGeneration"] ''
    ${lib.getExe copper.packages.waybar-confgen-hyprdots}
  '';

  home.packages = [copper.packages.waybar-confgen-hyprdots];

  copper.file.config = lib.genAttrs ["waybar/modules" "waybar/config.ctl"] (n: "config/${n}");
}