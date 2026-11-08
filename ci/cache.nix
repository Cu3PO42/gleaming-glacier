let
  niks3 = import ../shared/nix-cache.nix;
in
  niks3 // {
    hestia = {
      # Explicit names replace Hestia's defaults; retain the NixOS key.
      upstreamCacheKeyNames = [
        "cache.nixos.org-1"
        "nix-community.cachix.org-1"
      ];
    };
  }
