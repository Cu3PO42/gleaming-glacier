#!/usr/bin/env bash
set -euo pipefail

# Hestia normally omits cached outputs. Upload-enabled runs must realise and
# push every selected output, even when it only exists in Hestia or upstream.
args=()
for arg in "$@"; do
  if [[ "${CACHE_UPLOAD:-false}" == true && "$arg" == --check-cache-status ]]; then
    continue
  fi
  args+=("$arg")
done

exec nix run --inputs-from . nixpkgs#nix-eval-jobs -- "${args[@]}"
