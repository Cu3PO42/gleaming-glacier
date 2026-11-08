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
independent packages/checks, and configurations. The three phases share one
install/cache/build/upload step list through the `build-steps` YAML anchor;
each job declares its own matrix and dependency rules.
The eval job assembles a single `build-config` JSON object containing the
Nix settings, upstream filter keys, and upload policy, then passes it
to the reusable workflow. `NIX_CONFIG` is defined once in `ci.yml`.

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

Hestia excludes paths signed by `cache.nixos.org-1` or
`nix-community.cachix.org-1`, including when uploading derivation closures.
The exact key-name allowlist lives in `ci.upstreamCacheKeyNames` in
`shared/nix-cache.nix` and is passed to every Hestia instance. Explicit
key names replace Hestia's default list, so retain the NixOS key when
adding another cache. The filter uses signatures present in the local
store; it does not probe arbitrary caches for unsigned paths.

The eval job enables `filter-drv-closures`, and build jobs use
`hestia prefetch` to fetch omitted references from the upstream substituters
before importing Hestia's part. This is the behavior added by
[Hestia PR #136](https://github.com/Mic92/hestia/pull/136); without that
option, registered derivation closures bypass upstream filtering.
Existing unfiltered cache entries remain until they are garbage-collected.
The workflow accepts the flake's Nix configuration and sets up its
additional Nix Community cache in build jobs too; no account or cache
secret is needed.

The daily `hestia-gc.yml` workflow collects unused cache data on the default
branch. It can also be run manually, including in dry-run mode. GitHub's
default Actions cache quota is shared across all systems, so large desktop
or OS closures may still cause eviction. Hestia's cache is available inside
GitHub Actions only.

## Private niks3 uploads

Successful build jobs also push their output closures to the private OVH
cache through azurite's HTTPS upload API. The hostname, derived URL, and
repository/ref allowlists live in
[shared/nix-cache.nix](../shared/nix-cache.nix). The eval job reads this file
and includes the URL and upload decision in `build-config`; build
jobs still need no checkout or flake evaluation.

The initial policy permits `push` and `workflow_dispatch` on
`refs/heads/master` in `Cu3PO42/gleaming-glacier`. PRs and other refs build
with Hestia without private-cache uploads. The server enforces the same
repository, ref, and event claims using GitHub OIDC. CI has only the
`write` scope, and needs no API token, S3 credentials, or signing secret.

`Mic92/niks3-action` installs the upload client and supplies a renewable
OIDC token script with `skip-push: true`. Hestia retains the post-build
hook. After a successful build, `nix build --print-out-paths` supplies all
outputs (including grouped jobs and Hestia hits) to an explicit `niks3 push`.
An upload failure fails that job. Failed builds retain Hestia's intermediate
caching but do not push their partial outputs to niks3. Fully cached jobs
omitted by Hestia do not run and are not backfilled into S3.

The niks3 uploads deliberately keep complete runtime closures, including
dependencies available from upstream caches. Existing objects/NAR content
in our cache are deduplicated; Hestia's upstream filter does not apply to
these uploads. This keeps the pinned upstream client and its GC model
without maintaining a fork. Storage use can be measured after the initial
fill and subsequent nixpkgs updates; see
[measuring storage](../hosts/nixos/azurite/README.md#measuring-storage).

Hestia v3 has no native niks3 upload integration. Its
[storage-backend discussion](https://github.com/Mic92/hestia/issues/135)
points to Hestia beta's separate S3/OCI/WebDAV format. niks3's
[upstream-filtering PR #463](https://github.com/Mic92/niks3/pull/463)
was closed without merging: upstream deliberately retains full closures,
including dependencies that another cache could later garbage-collect.

Cache reads remain private and use the existing per-host S3 credentials;
the upload API is not a read substituter. Before enabling uploads, create
the subdomain's DNS record and deploy azurite's Caddy and OIDC
configuration. See [azurite's setup guide](../hosts/nixos/azurite/README.md).
When changing the hostname or allowlists, deploy the server before running
CI with the new settings.

`garnix.yaml` remains independent: disable the Garnix integration separately
if GitHub Actions is intended to replace it.
