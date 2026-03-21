---
name: install
description: Install binary dependencies for sentinels plugins. Use when user mentions バイナリインストール, install binaries, sentinels install, ツールインストール.
allowed-tools: Bash(*)
---

# Sentinels Binary Installer

Install all sentinels plugin binaries. Each tool's install script tries Homebrew first, then falls back to GitHub Releases.

Run the following command:

```bash
MARKETPLACE_ROOT="${CLAUDE_PLUGIN_ROOT}/../.."
for script in "$MARKETPLACE_ROOT"/*/hooks/install.sh; do
  tool="$(basename "$(dirname "$(dirname "$script")")")"
  echo "=== $tool ==="
  bash "$script"
  echo
done
```

Report which tools were installed and which were already present.
