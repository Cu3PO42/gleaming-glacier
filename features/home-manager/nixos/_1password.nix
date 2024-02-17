{config, lib, pkgs, ...}: with lib; let
  cfg = config.copper.feature.nixos._1password;
in {
  featureOptions = {
    gitSigning = {
      enable = mkEnableOption "Git Commit Signing via 1Password.";
      key = mkOption {
        type = types.str;
        default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGOEq8wEGishehE/xKfkhmv/t283pCMLDEbcJI+rib+5";
        description = ''
          The public key of the SSH key to be used for commit signing. If you're
          not Cu3PO42, you absolutely must customize this.
        '';
      };
    };
  };

  config = {
    programs.ssh.extraConfig = ''
      IdentityAgent ~/.1password/agent.sock
    '';

    programs.git.extraConfig = lib.mkIf (cfg.gitSigning.enable) {
      user.signingKey = cfg.gitSigning.key;
      gpg.format = "ssh";
      commit.gpgsign = lib.mkDefault true;
      "gpg.ssh".program = "${pkgs._1password-gui}/bin/op-ssh-sign";
    };
  };
}
