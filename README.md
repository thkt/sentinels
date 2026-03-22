# Sentinels

Claude Code plugin marketplace. Install 6 Rust-powered hook tools from a single marketplace.

## Install

```bash
claude plugins marketplace add github:thkt/sentinels
claude plugins install guardrails   # or any tool below
```

## Tools

| Tool                                             | Hook               | Trigger                    | Description                                                                   |
| ------------------------------------------------ | ------------------ | -------------------------- | ----------------------------------------------------------------------------- |
| [guardrails](https://github.com/thkt/guardrails) | PreToolUse         | Write\|Edit\|MultiEdit     | oxlint auto-provision + custom security rules                                 |
| [formatter](https://github.com/thkt/formatter)   | PostToolUse        | Write\|Edit\|MultiEdit     | oxfmt/biome auto-format                                                       |
| [reviews](https://github.com/thkt/reviews)       | PreToolUse         | Skill                      | Parallel static analysis context injection                                    |
| [gates](https://github.com/thkt/gates)           | PostToolUse        | Write\|Edit\|MultiEdit     | Parallel quality gates (lint, type-check, test, knip, tsgo, litmus, circular) |
| [chronicler](https://github.com/thkt/chronicler) | PostToolUse + Stop | Write\|Edit\|MultiEdit / — | Documentation staleness detection and update prompts                          |
| [shields](https://github.com/thkt/shields)       | PreToolUse + PermissionRequest | Bash / all | Command guard (44 patterns + N1-N7 normalization) + file ACL |

## Configuration

All tools work out of the box with sensible defaults. To customize, add the tool's key to `.claude/tools.json` in your project root.

### guardrails

All rules enabled by default. Disable specific rules:

```json
{
  "guardrails": {
    "rules": { "oxlint": false, "astSecurity": false }
  }
}
```

### formatter

All formatters enabled by default (oxfmt > biome priority). Disable specific formatters:

```json
{
  "formatter": {
    "biome": false
  }
}
```

### reviews

All tools enabled, activates on `/review` by default. Change target skills or disable tools:

```json
{
  "reviews": {
    "skills": ["audit"],
    "tools": { "react_doctor": false }
  }
}
```

### gates

All gates enabled by default. Disable specific gates or the review phase:

```json
{
  "gates": {
    "litmus": false,
    "review": false
  }
}
```

### chronicler

Docs directory defaults to `workspace/docs`. Change paths or enable the gate mode:

```json
{
  "chronicler": {
    "dir": "docs",
    "gate": true
  }
}
```

### shields

All guards enabled by default. Add custom patterns or configure ACL:

```json
{
  "shields": {
    "custom_patterns": [{"id": "kubectl-delete", "regex": "\\bkubectl\\s+delete\\b", "context": "Ask before deleting"}],
    "safe_dirs": ["workspace"],
    "deny_subagent": ["rules/"]
  }
}
```

See each tool's README for the full schema.

## Binary Installation

Each tool requires its binary. Install the CLI utility and run the install command:

```bash
claude plugins install sentinels
/sentinels:install
```

This installs all binaries at once (Homebrew if available, otherwise GitHub Releases). If you skip this step, the wrapper script will guide you on first hook trigger.

## License

MIT
