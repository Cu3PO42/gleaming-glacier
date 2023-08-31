{
  config,
  pkgs,
  ...
}: {
  programs.fish.enable = true;
  environment.shells = [pkgs.fish];

  chsh.users."${config.defaultUser}" = pkgs.fish;
  chsh.useWrapper = true;
}
