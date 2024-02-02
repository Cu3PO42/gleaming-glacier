{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf;
  wslAgentScript = "source ${lib.getExe pkgs.copper.wsl-ssh-agent}";
in {
  xdg.configFile."fish/conf.d/wsl_ssh_agent.fish" = mkIf config.copper.feature.fish.enable {
    text = ''replay "${wslAgentScript}"'';
  };

  programs.bash.initExtra = wslAgentScript;
  programs.zsh.initExtra = wslAgentScript;

  home.sessionVariables.WINHOME = "/mnt/c/Users/${config.home.username}/";

  home.packages = [
    (pkgs.writeShellScriptBin "xdg-open" "explorer.exe $(wslpath -w $1)")
  ];
}
