{
  pkgs,
  origin,
  copper,
  config,
  lib,
  ...
}: {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {};
  };

  programs.tmux = {
    enable = true;
    mouse = true;
  };

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;
  home.sessionVariables.DIRENV_LOG_FORMAT = "";

  programs.zoxide.enable = true;

  programs.bat = {
    enable = true;
    extraPackages = with pkgs.bat-extras; [
      (batgrep.overrideAttrs (old: { doCheck = false; }))
    ];
  };

  home.sessionVariables.NH_FLAKE = lib.mkDefault "${config.home.homeDirectory}/dotfiles";

  # nix-index provides a command-not-found implementation as well as
  # nix-locate, which helps with finding the package a binary is contained in.
  programs.nix-index.enable = true;
  # Instead of manually building the database on every host, we grab a
  # pre-built one.
  programs.nix-index.package = copper.inputs.nix-index-database.nix-index-with-db;

  # Install extra packages
  home.packages = with pkgs; [
    alejandra
    bottom
    copper.inputs.nix-index-database.comma-with-db
    entr
    eza
    fd
    fzf
    lsd
    htop
    httpie
    jq
    fastfetch
    nil
    copper.inputs.nix-search-cli
    nh
    nnn
    nurl
    copper.packages.plate
    ranger
    ripgrep
    ripgrep-all
    sd
    tealdeer
    tree
    tokei
  ];
}
