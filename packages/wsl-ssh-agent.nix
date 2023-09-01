{pkgs, ...}: let
  npiperelay = pkgs.stdenvNoCC.mkDerivation {
    name = "npiperelay";
    src = pkgs.fetchzip {
      url = "https://github.com/jstarks/npiperelay/releases/download/v0.1.0/npiperelay_windows_amd64.zip";
      hash = "sha256-GcwreB8BXYGNKJihE2xeelsroy+JFqLK1NK7Ycqxw5g=";
      stripRoot = false;
    };
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/bin
      mv npiperelay.exe $out/bin
    '';
  };

  # This approach is originally based on
  # https://stuartleeks.com/posts/wsl-ssh-key-forward-to-windows/ but has been
  # heavily simplified on the one side and extendet to automaticall install
  # npiperelay on the other side. We'd really like to define a systemd user
  # service, but that's not posisble on WSL2 by default. (since there is no
  # systemd).
in
  pkgs.writeShellScriptBin "wsl-ssh-agent" ''
    export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
    if ! (${pkgs.iproute2}/bin/ss -a | grep -q $SSH_AUTH_SOCK); then
      rm -f "$SSH_AUTH_SOCK"

      WINPATH="$(wslpath "$( (cd /mnt/c/; cmd.exe /c 'echo %LOCALAPPDATA%') | sed -e 's/\r//')")/nix-cache"
      if ! [ -e "$WSLPATH" ]; then
        mkdir "$WINPATH/nix-cache"
      fi

      if ! cmp -s ${npiperelay}/bin/npiperelay.exe "$WINPATH/npiperelay.exe"; then
        cp ${npiperelay}/bin/npiperelay.exe "$WINPATH/npiperelay.exe"
      fi

      (setsid ${pkgs.socat}/bin/socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"$WINPATH/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork &) >/dev/null 2>&1
    fi
  ''
