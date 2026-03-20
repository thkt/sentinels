# Sentinels

Claude Code plugin marketplace. Install 5 Rust-powered hook tools from a single marketplace.

## Install

```bash
claude plugins marketplace add github:thkt/sentinels
claude plugins install guardrails   # or any tool below
```

## Tools

| Tool                                             | Hook               | Trigger                    | Description                                                        |
| ------------------------------------------------ | ------------------ | -------------------------- | ------------------------------------------------------------------ |
| [guardrails](https://github.com/thkt/guardrails) | PreToolUse         | Write\|Edit\|MultiEdit     | oxlint/biome lint + AST security rules                             |
| [formatter](https://github.com/thkt/formatter)   | PostToolUse        | Write\|Edit\|MultiEdit     | oxfmt/biome auto-format                                            |
| [reviews](https://github.com/thkt/reviews)       | PreToolUse         | Skill                      | Parallel static analysis context injection                         |
| [gates](https://github.com/thkt/gates)           | Stop               | —                          | Parallel quality gates (lint, type-check, test, knip, tsgo, madge) |
| [chronicler](https://github.com/thkt/chronicler) | PostToolUse + Stop | Write\|Edit\|MultiEdit / — | Documentation staleness detection and update prompts               |

## Binary Installation

Each tool requires its binary. On first hook trigger, if the binary is not found, the wrapper script will guide you:

```bash
# Option 1: Homebrew
brew install thkt/tap/<tool>

# Option 2: Run the bundled install script
~/.claude/plugins/sentinels/<tool>/hooks/install.sh
```

## License

MIT
