{
  pkgs,
  lib,
  config,
  ...
}: let
  hasFish = config.programs.fish.enable;
in {
  home.packages = [pkgs.github-copilot-cli];

  programs.fish.shellAliases.",," = "__copilot_what-the-shell";
  programs.fish.plugins = with pkgs.fishPlugins; [
    {
      name = "github-copilot-cli";
      src = github-copilot-cli-fish.src;
    }
  ];
}
