[
  # Exclusions only remove standalone CI jobs; a selected configuration can
  # still depend on an excluded package.

  # Installer exclusion carried over from garnix.yaml.
  "nixosConfigurations.installer"

  # Marked meta.broken in this repository. Garnix already excluded the SDDM
  # theme on x86_64-linux; it is broken on the newly covered systems too.
  "packages.*.sddm-theme-corners"
  "packages.*.illogical-impulse"

  # Depends on GTK2, which the locked nixpkgs marks broken.
  "packages.*.gtkrc-reload"

  # Uses the cairomm alias removed by the locked nixpkgs.
  "packages.*.microtex"

  # References lib.licenses.agpl3, which is absent in the locked nixpkgs.
  "packages.*.rga-fzf"

  # Use * for any single attribute component, for example:
  # "packages.*.some-package"
  # "homeConfigurations.some-user@some-host"
]
