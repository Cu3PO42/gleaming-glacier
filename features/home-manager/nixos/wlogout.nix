{pkgs, ...}: {
  programs.wlogout.enable = true;
  home.packages = [pkgs.wlogout-launcher-hyprdots];
  copper.file.config."wlogout" = "config/wlogout";
}
