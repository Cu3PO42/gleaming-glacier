{config, lib, ...}: {
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Allow all users to use system authentication to unlock 1Password.
    polkitPolicyOwners = lib.attrNames config.users.users;
  };
}