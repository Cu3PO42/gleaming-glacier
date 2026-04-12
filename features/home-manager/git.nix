{
  pkgs,
  config,
  ...
}: {
  programs.git = {
    enable = true;
    lfs.enable = true;

    # Default value; needs to be set to avoid warning
    signing.format = null;
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
