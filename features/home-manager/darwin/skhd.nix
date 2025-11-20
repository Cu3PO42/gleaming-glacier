{config, ...}: {
  services.skhd = {
    enable = true;
    maestroIntegration = true;
  };
  # We need some additional settings that aren't available directly on the service config
  launchd.agents.skhd = {
    # skhd executes everything in the user's login shell, but we want bash for portability
    config.EnvironmentVariables = {
      SHELL = "/bin/bash";
    };
  };
}