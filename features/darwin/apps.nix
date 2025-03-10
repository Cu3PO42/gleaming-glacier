{pkgs, lib, ...}: {
  homebrew.enable = true;
  homebrew.casks = [
    "1password"
    "1password-cli"
    "firefox"
    "firefox-developer-edition"
    "google-chrome"
    "iterm2"
    "jetbrains-toolbox"
    "launchcontrol"
    "orbstack"
    "tailscale"
    "utm"
    "visual-studio-code"
    "wezterm"
  ];
  homebrew.taps = [
    "1password/tap"
    "homebrew/cask-versions"
  ];
  homebrew.masApps = {
    "Xcode" = 497799835;
    "Amphetamine" = 937984704;
    "1Password for Safari" = 1569813296;
    "Microsoft Remote Desktop" = 1295203466;
  };

  fonts.packages = with pkgs; [
    fira-mono
    fira-code
    victor-mono
    ibm-plex
  ] ++ builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts);
}
