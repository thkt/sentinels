#!/usr/bin/env bats

setup() {
  WRAPPER="$BATS_TEST_DIRNAME/../guardrails/hooks/wrapper.sh"
  MOCK_DIR="$(mktemp -d)"

  # Create mock binary that echoes stdin + args
  cat > "$MOCK_DIR/guardrails" << 'MOCK'
#!/usr/bin/env bash
if [ $# -gt 0 ]; then
  echo "args:$*"
fi
cat
MOCK
  chmod +x "$MOCK_DIR/guardrails"

  # Reuse for chronicler subcommand test
  cp "$MOCK_DIR/guardrails" "$MOCK_DIR/chronicler"
}

teardown() {
  rm -rf "$MOCK_DIR"
}

# T-007: wrapper バイナリあり — stdin が binary に pipe される
@test "pipes stdin to binary when binary is in PATH" {
  export PATH="$MOCK_DIR:$PATH"
  result="$(echo '{"tool":"Write"}' | "$WRAPPER" guardrails)"
  [ "$result" = '{"tool":"Write"}' ]
}

# T-008: wrapper バイナリなし — install.sh 案内が stderr に出力、exit 0
@test "exits 0 and prints install message when binary not in PATH" {
  run env PATH="/usr/bin:/bin" bash "$WRAPPER" guardrails <<< '{"tool":"Write"}'
  [ "$status" -eq 0 ]
  [[ "$output" == *"not installed"* ]]
  [[ "$output" == *"install.sh"* ]]
}

# T-016: wrapper subcommand 渡し — subcommand が binary に渡される
@test "passes subcommands to binary" {
  export PATH="$MOCK_DIR:$PATH"
  result="$(echo '{"tool":"Write"}' | "$WRAPPER" chronicler edit)"
  [[ "$result" == *"args:edit"* ]]
  [[ "$result" == *'{"tool":"Write"}'* ]]
}
