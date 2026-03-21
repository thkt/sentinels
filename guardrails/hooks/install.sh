#!/usr/bin/env bash
TOOL="guardrails"
REPO="thkt/guardrails"
source "$(cd "${BASH_SOURCE[0]%/*}/../.." && pwd)/shared/hooks/install-lib.sh"

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  set -euo pipefail
  install_tool "$@"
fi
