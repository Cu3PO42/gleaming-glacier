{
  pkgs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
  hasPackage = pname: lib.any (p: p ? pname && p.pname == pname) config.home.packages;
  hasLazygit = config.programs.lazygit.enable;
  hasLsd = hasPackage "lsd";
  hasBat = config.programs.bat.enable;
  lsCmd =
    if hasLsd
    then "lsd"
    else "ls";
  catCmd =
    if hasBat
    then "bat"
    else "cat";
in {
  programs.starship = {
    enable = true;
    settings = {
      container.disabled = true;
      nix_shell = {
        format = "via [$symbol \($name\)]($style) ";
      };
    };
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      fish_vi_key_bindings
      # The vi bindings overwrite the fzf bindings, appararently.
      fzf_configure_bindings
    '';
    shellAliases = {
      he = "$EDITOR ${config.copper.file.symlink.base}";
      hes = "he; hs";
      nr = "nix run nixpkgs#$argv[1] -- $argv[2..-1]";
      nsh = "nix shell (for prog in $argv; echo \"nixpkgs#$prog\"; end)";
      nd = "nix develop -c $SHELL";
      ns = "nix-search --channel=unstable";
      lg = mkIf hasLazygit "lazygit";
    };
    functions = {
      # Disable greeting
      fish_greeting = "";

      hs.body = ''
        pushd ${config.copper.file.symlink.base}
        git add --all
        home-manager switch
        popd
      '';

      lb.body = ''
        if test -d $argv
            command ${lsCmd} $argv
        else if test  -f $argv
            command ${catCmd} $argv
        else
            echo -e "\033[0;31m$argv: target does not exist \033[0m"
            return 127
        end
      '';
    };
    plugins = with pkgs.fishPlugins; [
      {
        name = "fzf";
        src = fzf-fish.src;
      }
      {
        name = "forgit";
        src = forgit.src;
      }
      {
        name = "autopair-fish";
        src = autopair-fish.src;
      }
      {
        name = "replay";
        src = pkgs.fetchFromGitHub {
          owner = "jorgebucaran";
          repo = "replay.fish";
          rev = "bd8e5b89ec78313538e747f0292fcaf631e87bd2";
          hash = "sha256-bM6+oAd/HXaVgpJMut8bwqO54Le33hwO9qet9paK1kY=";
        };
      }
      {
        name = "bang-bang";
        src = pkgs.fetchFromGitHub {
          owner = "oh-my-fish";
          repo = "plugin-bang-bang";
          rev = "816c66df34e1cb94a476fa6418d46206ef84e8d3";
          hash = "sha256-35xXBWCciXl4jJrFUUN5NhnHdzk6+gAxetPxXCv4pDc=";
        };
      }
      {
        name = "ayu-theme";
        src = pkgs.fetchFromGitHub {
          owner = "edouard-lopez";
          repo = "ayu-theme.fish";
          rev = "d351d24263d87bef3a90424e0e9c74746673e383";
          hash = "sha256-rx9izD2pc3hLObOehuiMwFB4Ta5G1lWVv9Jdb+JHIz0=";
        };
      }
    ];
  };
}
