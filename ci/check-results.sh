#!/usr/bin/env bash
set -euo pipefail

[[ "$EVAL" == success ]]
for system in X86_64_LINUX AARCH64_LINUX AARCH64_DARWIN; do
  actual="BUILD_$system"
  expected="EXPECTED_BUILD_$system"
  [[ "${!actual}" == "${!expected}" ]]
done
[[ "$UPLOAD_CACHED" == "$EXPECTED_UPLOAD" ]]
