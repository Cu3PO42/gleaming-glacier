{
  pkgs,
  config,
  ...
}: {
  programs.git = {
    enable = true;
    delta.enable = true;
    lfs.enable = true;

    userName = "Cu3PO42";
    userEmail = "cu3po42@gmail.com";
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
