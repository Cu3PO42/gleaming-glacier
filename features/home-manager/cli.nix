{
  pkgs,
  config,
  outputs,
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
  programs.nix-index.package = pkgs.inputs.nix-index-database.nix-index-with-db;

  # Install extra packages
  home.packages = with pkgs; [
    alejandra
    bottom
    inputs.nix-index-database.comma-with-db
    entr
    eza
    fd
    fzf
    lsd
    httpie
    jq
    neofetch
    nil
    inputs.nix-search-cli
    nnn
    nurl
    plate
    ranger
    ripgrep
    ripgrep-all
    rga-fzf
    sd
    tealdeer
    tree
    tokei
  ];

  # This is a fix for ripgrep-all not building on current nixpkgs.
  # TODO: remove once nixos/nixpkgs#250306 is reolved
  copper.patches.ripgrep-all = [(pkgs.fetchpatch {
    url = "https://gist.githubusercontent.com/liketechnik/2be6df2fa77728239d545a0d155afcc4/raw/4d5cf1afe207315f999db06f0cb4b5b816150b38/0001-fix-adapters-pandoc-adjust-flag-for-requesting-atx-h.patch";
    hash = "sha256-4uWyXcr8aYH65Mh9Ay6JQBJHZ8QaU7+dwWN/Ceif2TQ";
  })];
}
