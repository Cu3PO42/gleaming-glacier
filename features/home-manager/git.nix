{
  pkgs,
  config,
  ...
}: {
  programs.git = {
    enable = true;
    delta.enable = true;
    lfs.enable = true;
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
