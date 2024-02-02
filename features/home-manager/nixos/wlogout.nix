{pkgs, ...}: {
  programs.wlogout.enable = true;
  home.packages = [pkgs.copper.wlogout-launcher-hyprdots];
  copper.file.config."wlogout" = "config/wlogout";
}
