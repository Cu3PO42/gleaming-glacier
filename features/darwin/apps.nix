{pkgs, ...}: {
  homebrew.enable = true;
  homebrew.casks = [
    "1password"
    "1password-cli"
    "firefox"
    "firefox-developer-edition"
    "google-chrome"
    "iterm2"
    "jetbrains-toolbox"
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

  fonts.fontDir.enable = true;
  fonts.fonts = with pkgs; [
    fira-mono
    fira-code
    nerdfonts
    victor-mono
    ibm-plex
  ];
}
