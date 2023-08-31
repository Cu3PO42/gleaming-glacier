{config, ...}: {
  copper.file.symlink.enable = true;
  copper.file.symlink.base = "${config.home.homeDirectory}/dotfiles";
}
