{
  pkgs,
  config,
  lib,
  ...
}: let
  hasGit = config.programs.git.enable;
in {
  # TODO: figure out why smartindent is on (at least for nix files)
  # TODO: fix folding (consider nvim-ufo?)
  # TODO: get debugging to work
  # TODO: fix tree-sitter grammars by installing through home-manager
  # TODO: checkout dropbar.nvim
  # TODO: git blame in nvim?
  home.sessionVariables.EDITOR = "nv";
  programs.neovim.enable = true;
  programs.neovim.extraPackages = with pkgs; [
    # Needed by our configuration
    fd
    ripgrep

    luajit # Used by some neovim packages
  ];

  home.packages = with pkgs; [
    # Scipt to treat a directory argument as the working directory
    (writeShellScriptBin "nv" ''
      if test -d $1; then
          pushd $1
          nvim .
      else
          file=$(realpath $1)
          pushd $(dirname $1)
          ${
        if hasGit
        then ''          if git rev-parse --show-toplevel; then
                      cd $(git rev-parse --show-toplevel)
                  fi''
        else ""
      }
          nvim $file
      fi
      popd
    '')
  ];

  copper.file.config."nvim" = "config/nvim";
}
