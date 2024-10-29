{...}: {
  updates = final: prev: {
    vscode = if final.stdenv.hostPlatform.system == "x86_64-linux" && final.lib.versionOlder prev.vscode.version "1.95.0" then prev.vscode.overrideAttrs (_: _: {
      version = "1.95.0";
      src = final.fetchurl {
        name = "VSCode_1.95.0_linux-x64.tar.gz";
        url = "https://update.code.visualstudio.com/1.95.0/linux-x64/stable";
        hash = "sha256-pVTwb3FJceTTVYsW7tvNIqptpsAE5k+2pC78a4qejok=";
      };
    }) else prev.vscode;
  };
}
