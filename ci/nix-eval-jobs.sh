#!/usr/bin/env bash
set -euo pipefail

# Preserve Hestia's cache checks and save the same evaluation for the uploader.
# pipefail ensures evaluation failures still fail the matrix action.
nix run --inputs-from . nixpkgs#nix-eval-jobs -- "$@" | tee "${NIX_EVAL_JOBS_OUTPUT:?}"
