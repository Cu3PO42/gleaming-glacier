{
  config,
  lib,
  pkgs,
  copper,
  ...
}: {
  copper.feature.nixos.waybar.enable = true;

  systemd.user.services.waybar = let
    confgen = "${lib.getExe copper.packages.waybar-confgen-hyprdots}";
  in {
    Service.ExecStartPre = confgen;
    Service.ExecReload = lib.mkForce confgen;
  };


  home.packages = [copper.packages.waybar-confgen-hyprdots];

  copper.file.config = lib.genAttrs ["waybar/modules" "waybar/config.ctl"] (n: "config/${n}");
}