{
  pkgs,
  config,
  ...
}: {
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings.user.name = "Cu3PO42";
    settings.user.email = "cu3po42@gmail.com";
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.lazygit = {
    enable = true;
    settings.git = {
      autoFetch = false;
      paging = {
        colorArg = "always";
        pager = "delta --paging=never";
      };
    };
  };
}
