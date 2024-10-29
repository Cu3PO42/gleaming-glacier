{origin, options, config, lib, pkgs, ...}: with lib; let
  isHomeManager = options ? home;
  isSubmoduleHomeManager = isHomeManager && config.submoduleSupport.enable;
  configPath = if isHomeManager then config.xdg.configHome else "/etc";
  configSettingPt1 = if isHomeManager then "xdg" else "environment";
  configSettingPt2 = if isHomeManager then "configFile" else "etc";
in {
  config = {
    # Nix configuration options do not exist for Home-Manager when used from
    # within a NixOS or nix-darwin configuration.
    nix = optionalAttrs (!isSubmoduleHomeManager) {
      # A package must be specified for the settings below to work.
      package = pkgs.nix;

      settings = {
        # Allow Flakes. nix-command is required for the intuitive Flake CLI
        # interface. Repl-flake allows us to load Flakes in `nix repl`.
        experimental-features = ["nix-command" "flakes"];

        # This enables the use of binary caches so we need to build less.
        extra-substituters = [
          "https://cache.garnix.io"
          "https://nix-community.cachix.org"
          "https://hyprland.cachix.org"
        ];

        # Keys that store paths are signed with.
        extra-trusted-public-keys = [
          "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];

        # Disable the warning about dirty git checkouts.
        warn-dirty = false;
      };

      # Remove store paths older than 30 days that are not reachable from a GC
      # root.
      gc = {
        automatic = true;
        options = "--delete-older-than 30d";
      };

      # We pin the system's nixpkgs to what we have in the Flake.
      # Both in the Flake registry, so nixpkgs resolves to our version by default
      # when used with a command such as `nix run nixpkgs#hello`,
      registry.nixpkgs.flake = origin.inputs.nixpkgs;
    } // optionalAttrs (!isHomeManager) {
      # but we also create a channel pointing to the same version, and add it
      # to the search path.
      nixPath = [
        "nixpkgs=${configPath}/channels/nixpkgs"
      ];
      # The folder above is created by an external setting.
    };

    # Create a nix-channel named nixpkgs to point to our nixpkgs input.
    ${configSettingPt1}.${configSettingPt2} = lib.mkIf (!isHomeManager) {
      "channels/nixpkgs".source = origin.inputs.nixpkgs.outPath;
    };

    # This modifies the packages that are available to install as part of this
    # configuration only.
    nixpkgs.config.allowUnfree = true;
    # Workaround for the above setting not working.
    nixpkgs.config.allowUnfreePredicate = _: true;
  };
}
