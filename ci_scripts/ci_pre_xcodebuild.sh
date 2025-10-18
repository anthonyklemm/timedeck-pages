#!/bin/bash
set -euo pipefail
cd "${CI_PRIMARY_REPOSITORY_PATH:-$(git rev-parse --show-toplevel)}"
echo ">>> PRE-XCODEBUILD: nothing to do (commit: $(git rev-parse --short HEAD))"
exit 0