[
  # We only need that as an ISO. Wasteful to always build.
  "nixosConfigurations.installer"

  # Gtk2 is marked deprecated in the locked nixpkgs and evaluating it fails.
  # However, the package itself still works, so it isn't marked broken.
  "packages.*.gtkrc-reload"
]
