{
  pkgs,
  inputs,
  ...
}: {
  programs.ssh.enable = true;

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
      batgrep
    ];
  };

  # nix-index provides a command-not-found implementation as well as
  # nix-locate, which helps with finding the package a binary is contained in.
  programs.nix-index.enable = true;
  # Instead of manually building the database on every host, we grab a
  # pre-built one.
  programs.nix-index.package = inputs.nix-index-database.packages.${pkgs.system}.nix-index-with-db;

  # Install extra packages
  home.packages = with pkgs; [
    alejandra
    bottom
    inputs.nix-index-database.packages.${pkgs.system}.comma-with-db
    entr
    eza
    fd
    fzf
    lsd
    httpie
    jq
    neofetch
    nil
    inputs.nix-search-cli.packages.${pkgs.system}.default
    nnn
    nurl
    copper.plate
    ranger
    ripgrep
    ripgrep-all
    sd
    tealdeer
    tree
    tokei
  ];
}
