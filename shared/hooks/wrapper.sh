#!/usr/bin/env bash
set -euo pipefail

if [ $# -eq 0 ]; then
  echo "Usage: wrapper.sh <tool> [subcommand...]" >&2
  exit 1
fi

TOOL="$1"
shift

if ! command -v "$TOOL" &>/dev/null; then
  cat > /dev/null
  echo "${TOOL} not installed. Run: $(cd "${0%/*}/../.." && pwd)/${TOOL}/hooks/install.sh" >&2
  exit 0
fi

exec "$TOOL" "$@"
