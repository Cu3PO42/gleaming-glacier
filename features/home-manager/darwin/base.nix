{config, ...}: {
  programs.fish.shellAliases = {
    ds = "darwin-rebuild switch --flake ~/dotfiles";
  };

  programs.ssh.settings = {
    "*" = {
      IdentityAgent = "\"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock\"";
    };
  };

  copper.file.config."karabiner/karabiner.json" = "config/karabiner/karabiner.json";
}
