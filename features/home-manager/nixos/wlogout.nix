{pkgs, copper, ...}: {
  programs.wlogout.enable = true;
  home.packages = [copper.packages.wlogout-launcher-hyprdots];
  copper.file.config."wlogout" = "config/wlogout";
}
