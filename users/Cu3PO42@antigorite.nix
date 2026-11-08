{ 
  main = {
    copper.features = [
      "git"
      "fish"
      "catppuccin"
      "neovim"
      "lunarvim"
      "copilot"
      "cli"
      "rust"
      "wezterm"
      "link-config"
      "darwin/base"
      "darwin/wm"
      "darwin/orb"
      "darwin/aerospace"
      "darwin/sketchybar"
    ];
    home.stateVersion = "22.11";

    # Workaround for 1Password being broken currently. It fails during installation of shell completions,
    # so we just skip that step.
    copper.perSystem.useConfigPkgs = true;
    nixpkgs.overlays = [(final: prev: { _1password-cli = prev._1password-cli.overrideAttrs (_: _: { postInstall = ""; }); })];
  };
  system = "aarch64-darwin";
}
