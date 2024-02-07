{
  pkgs,
  config,
  options,
  origin,
  ...
}: {
  # Reflects the version at the time of initial setup, do not update
  home.stateVersion = "22.11";

  nix =
    {
      package = pkgs.nix;
      settings = {
        warn-dirty = false;
        experimental-features = "nix-command flakes repl-flake";
      };
      registry.nixpkgs.flake = origin.inputs.nixpkgs;
    }
    // (
      if options.nix ? nixPath
      then {
        # When using Home-Manager as a NixOS module, these options do not exist at all.
        nixPath = [
          "nixpkgs=${config.xdg.configHome}/channels/nixpkgs"
        ];
      }
      else {}
    );
  xdg.configFile."channels/nixpkgs".source = origin.inputs.nixpkgs.outPath;

  nixpkgs.config.allowUnfree = true;
  # Workaround for the above setting not working.
  nixpkgs.config.allowUnfreePredicate = _: true;
  # Add all of our own overlays
  nixpkgs.overlays = [origin.config.flake.overlays.additions];

  # Persist Home Manager
  programs.home-manager.enable = true;

  # Set basic settings
  home.homeDirectory =
    if pkgs.lib.strings.hasSuffix "linux" pkgs.system
    then "/home/${config.home.username}"
    else "/Users/${config.home.username}";

  # Nix Flakes and Home-Manager often need Git
  programs.git.enable = true;

  # Symlink the flake to enable easier switches later
  copper.file.config."home-manager/flake.nix" = "flake.nix";
}
