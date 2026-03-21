#!/usr/bin/env bats

setup() {
  WRAPPER="$BATS_TEST_DIRNAME/../shared/hooks/wrapper.sh"
  MOCK_DIR="$(mktemp -d)"

  cat > "$MOCK_DIR/guardrails" << 'MOCK'
#!/usr/bin/env bash
if [ $# -gt 0 ]; then
  echo "args:$*"
fi
cat
MOCK
  chmod +x "$MOCK_DIR/guardrails"

  cp "$MOCK_DIR/guardrails" "$MOCK_DIR/chronicler"

  cat > "$MOCK_DIR/failguard" << 'MOCK'
#!/usr/bin/env bash
cat >/dev/null
exit 1
MOCK
  chmod +x "$MOCK_DIR/failguard"
}

teardown() {
  rm -rf "$MOCK_DIR"
}

@test "pipes stdin to binary when binary is in PATH" {
  export PATH="$MOCK_DIR:$PATH"
  result="$(echo '{"tool":"Write"}' | "$WRAPPER" guardrails)"
  [ "$result" = '{"tool":"Write"}' ]
}

@test "exits 0 and prints install message when binary not in PATH" {
  run env PATH="/usr/bin:/bin" bash "$WRAPPER" guardrails <<< '{"tool":"Write"}'
  [ "$status" -eq 0 ]
  [[ "$output" == *"not installed"* ]]
  [[ "$output" == *"install.sh"* ]]
}

@test "passes subcommands to binary" {
  export PATH="$MOCK_DIR:$PATH"
  result="$(echo '{"tool":"Write"}' | "$WRAPPER" chronicler edit)"
  [[ "$result" == *"args:edit"* ]]
  [[ "$result" == *'{"tool":"Write"}'* ]]
}

@test "exits 1 with usage when called with no arguments" {
  run bash "$WRAPPER" <<< '{"tool":"Write"}'
  [ "$status" -eq 1 ]
  [[ "$output" == *"Usage"* ]]
}

@test "propagates non-zero exit code from binary" {
  export PATH="$MOCK_DIR:$PATH"
  run bash "$WRAPPER" failguard <<< '{"tool":"Write"}'
  [ "$status" -eq 1 ]
}

@test "handles empty stdin without hanging" {
  export PATH="$MOCK_DIR:$PATH"
  run bash "$WRAPPER" guardrails < /dev/null
  [ "$status" -eq 0 ]
}
