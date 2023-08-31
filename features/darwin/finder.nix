{...}: {
  system.defaults = {
    LaunchServices.LSQuarantine = false;
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      NSDocumentSaveNewDocumentsToCloud = false;
    };
    dock = {
      appswitcher-all-displays = true;
      minimize-to-application = true;
      mru-spaces = false;
    };
    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      CreateDesktop = false;
      FXEnableExtensionChangeWarning = false;
      FXPreferredViewStyle = "Nlsv"; # Prefer list view
      FXDefaultSearchScope = "SCcf"; # By default search only inside the folder
      ShowPathbar = true;
    };
    loginwindow.GuestEnabled = false;
    CustomSystemPreferences = {
      "com.apple.desktopservices".DSDontWriteNetworkStores = true;
      "com.apple.TimeMachine".DoNotOfferNewDisksForBackup = true;
    };
  };
}
