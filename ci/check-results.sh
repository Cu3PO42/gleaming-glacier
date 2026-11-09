#!/usr/bin/env bash
set -euo pipefail

[[ "$EVAL" == success ]]
[[ "$BUILD" == "$EXPECTED_BUILD" ]]
[[ "$UPLOAD_CACHED" == "$EXPECTED_UPLOAD" ]]
