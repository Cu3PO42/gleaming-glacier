{
  system = {
    path = ./system;
    description = ''
      A Flake to create system configurations based on Copper's dotfiles.
    '';
    welcomeText = ''
      You have just created a new Flake for NixOS, macOS, and Home-Manager
      configurations based on the one by Cu3PO42.

      While you can re-use a lot of configuration snippets from Copper's
      dotfiles, you will still need to create your own configuration files for
      each system that you want to manage. Please see the accompanying
      README for more instructions.

      TODO: make sure this is accurate
      Please make sure to adjust the namespace in flake.nix. You may use the
      ./welcome.sh script to do so.
    '';
  };
}
