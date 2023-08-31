{...}: {
  programs.ssh.matchBlocks = {
    orb = {
      hostname = "localhost";
      user = "default";
      port = 32222;
      identityFile = "~/.orbstack/ssh/id_ed25519";
    };
  };
}
