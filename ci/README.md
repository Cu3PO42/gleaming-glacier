# Nix CI

GitHub Actions uses [Hestia](https://github.com/Mic92/hestia) to evaluate
`ciJobs` once and build the uncached outputs in a matrix. The output contains:

- `packages` and `checks` on the flake's declared systems: `x86_64-linux`,
  `aarch64-linux`, and `aarch64-darwin`. Package availability is already
  filtered by the flake's package loader.
- Home Manager activation packages, NixOS system toplevels, and nix-darwin
  systems on each configuration's own system, when it is in that list.
  Embedded Home Manager configurations are built as part of their system.

The runners are `ubuntu-24.04`, `ubuntu-24.04-arm`, and `macos-15`, respectively.
Build jobs fetch derivations from Hestia and build by store path, without
checking out or evaluating the flake again. `Nix CI result` is the stable status
check for branch protection; it also handles a fully cached, empty matrix.
The evaluated matrix is split by platform. Each platform calls
`build-platform.yml` with three matrices: packages needed by configurations,
independent packages/checks, and configurations.

## Exclusions

Edit [exclude.nix](./exclude.nix) to remove CI jobs by their original flake
output path. `*` matches one complete attribute component, for example:

```nix
[
  "packages.*.some-package"
  "packages.aarch64-linux.another-package"
  "checks.aarch64-darwin.some-check"
  "homeConfigurations.user@host"
  "nixosConfigurations.some-host"
  "darwinConfigurations.some-mac"
]
```

The installer exclusion from `garnix.yaml` is retained, and the broken SDDM
theme is excluded on all systems. `exclude.nix` also documents the existing
evaluation failures excluded from the initial matrix: `illogical-impulse`,
`gtkrc-reload`, `microtex`, and `rga-fzf`. Remove these entries as the packages
are repaired.

An exclusion removes the standalone CI job, not dependencies of other selected
outputs. It does not remove anything from the public `packages` or configuration outputs.
Configurations are excluded before evaluating their build outputs, so an
excluded configuration may be broken. Package discovery still uses the
existing loader's platform metadata filtering, which evaluates packages.

Inspect the selected package names locally with:

```sh
nix eval --json .#ciJobs.packages --apply 'builtins.mapAttrs (_: builtins.attrNames)'
nix eval --json .#ciJobs.nixosConfigurations --apply builtins.attrNames
```

New files must be added to Git before ordinary Git flake commands see them.
During development, use `path:.#ciJobs` to include untracked files.

## Cache reuse

After Hestia evaluates once, `ci/matrix.py` queries each platform's pending
configuration derivations with `nix-store --query --requisites`. This reads
the already-instantiated transitive build dependency graph; it performs no
builds or additional flake evaluation.

Packages/checks whose exact `.drv` paths occur in that graph run in the
prerequisite matrix. Configurations wait for that matrix and its Hestia cache
uploads. All remaining packages/checks run independently, so configurations
do not wait for them. If all prerequisite packages are cached, configurations
can start immediately. Cached configuration jobs are already omitted by
Hestia, so packages needed only by those configurations do not cause waits.

Both matrices still contribute to `Nix CI result`. An independent package
failure fails CI while allowing configuration builds to proceed. Linux
configurations can start while Darwin packages are still building, and the
two Linux architectures also progress independently.

Matching uses derivation paths rather than package names: a configuration's
override only matches a standalone package if their derivations are identical.
For a Hestia group, every installable is checked; the whole group becomes a
prerequisite if any member is needed. Configurations can then substitute
matching packages from the cache while each output keeps its own matrix job.

The eval job runs the dependency partitioning tests before evaluation. Run
them locally with `python3 -m unittest discover -s tests -p 'test_ci_matrix.py'`.

Shared uncached dependencies can still be built by multiple concurrent jobs
within a phase. Packages overridden by a configuration also have different
store paths and need separate builds. Hestia's `meta.hestia.group` can group
related derivations onto one runner if that becomes costly; the group name
must be unique per system. Building all outputs for a system together would
avoid concurrency duplicates completely, at the cost of parallelism.

Hestia caches only paths that are not signed by `cache.nixos.org`, including
when uploading derivation closures. The workflow uses `hestia prefetch` to
restore those filtered closures. The workflow accepts the flake's Nix
configuration and sets up its additional Nix Community cache in build jobs
too; no account or cache secret is needed.

The daily `hestia-gc.yml` workflow collects unused cache data on the default
branch. It can also be run manually, including in dry-run mode. GitHub's
default Actions cache quota is shared across all systems, so large desktop
or OS closures may still cause eviction. Hestia's cache is available inside
GitHub Actions only.

`garnix.yaml` remains independent: disable the Garnix integration separately
if GitHub Actions is intended to replace it.
