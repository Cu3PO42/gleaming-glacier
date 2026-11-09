#!/usr/bin/env bash
set -euo pipefail

if [[ "$ANY_JOBS" == true && ! "$MANIFEST_VERSION" =~ ^[1-9][0-9]*$ ]]; then
  echo '::error::Hestia did not commit the derivation manifest. Rerun evaluation before starting builds.'
  exit 1
fi
