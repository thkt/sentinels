#!/usr/bin/env bats

setup() {
  INSTALL_LIB="$BATS_TEST_DIRNAME/../shared/hooks/install-lib.sh"
  MOCK_DIR="$(mktemp -d)"
  TOOL="guardrails"
  REPO="thkt/guardrails"
  source "$INSTALL_LIB"
  export PATH="$MOCK_DIR:$PATH"
}

teardown() {
  rm -rf "$MOCK_DIR"
}

mock_uname() {
  local os="$1" arch="$2"
  cat > "$MOCK_DIR/uname" << MOCK
#!/usr/bin/env bash
case "\$1" in
  -s) echo "$os" ;;
  -m) echo "$arch" ;;
esac
MOCK
  chmod +x "$MOCK_DIR/uname"
}

setup_github_release_mocks() {
  mock_uname Darwin arm64
  export TOOL

  cat > "$MOCK_DIR/curl" << 'MOCK'
#!/usr/bin/env bash
while [ $# -gt 0 ]; do
  if [ "$1" = "-o" ]; then touch "$2"; break; fi
  shift
done
MOCK
  chmod +x "$MOCK_DIR/curl"

  cat > "$MOCK_DIR/tar" << 'MOCK'
#!/usr/bin/env bash
while [ $# -gt 0 ]; do
  if [ "$1" = "-C" ]; then touch "${2}/${TOOL}"; break; fi
  shift
done
MOCK
  chmod +x "$MOCK_DIR/tar"

  export INSTALL_DIR="$MOCK_DIR/install"
  export PATH="$MOCK_DIR:/usr/bin:/bin"
}

@test "detect_platform returns aarch64-apple-darwin for macOS ARM" {
  mock_uname Darwin arm64
  result="$(detect_platform)"
  [ "$result" = "aarch64-apple-darwin" ]
}

@test "detect_platform returns x86_64-unknown-linux-gnu for Linux x86_64" {
  mock_uname Linux x86_64
  result="$(detect_platform)"
  [ "$result" = "x86_64-unknown-linux-gnu" ]
}

@test "detect_platform exits 1 for unsupported OS" {
  mock_uname FreeBSD x86_64
  run detect_platform
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unsupported OS"* ]]
}

@test "detect_platform normalizes amd64 to x86_64" {
  mock_uname Linux amd64
  result="$(detect_platform)"
  [ "$result" = "x86_64-unknown-linux-gnu" ]
}

@test "detect_platform normalizes aarch64 to aarch64" {
  mock_uname Darwin aarch64
  result="$(detect_platform)"
  [ "$result" = "aarch64-apple-darwin" ]
}

@test "detect_platform returns 1 for unsupported architecture" {
  mock_uname Linux s390x
  run detect_platform
  [ "$status" -eq 1 ]
  [[ "$output" == *"Unsupported architecture"* ]]
}

@test "install_tool skips install when binary already in PATH" {
  cat > "$MOCK_DIR/guardrails" << 'MOCK'
#!/usr/bin/env bash
echo "mock"
MOCK
  chmod +x "$MOCK_DIR/guardrails"
  run install_tool
  [ "$status" -eq 0 ]
  [[ "$output" == *"already installed"* ]]
}

@test "install_tool uses brew when available" {
  cat > "$MOCK_DIR/brew" << 'MOCK'
#!/usr/bin/env bash
echo "brew install $*"
MOCK
  chmod +x "$MOCK_DIR/brew"
  export PATH="$MOCK_DIR:/usr/bin:/bin"
  run install_tool
  [ "$status" -eq 0 ]
  [[ "$output" == *"thkt/tap/guardrails"* ]]
}

@test "download uses curl when available" {
  cat > "$MOCK_DIR/curl" << 'MOCK'
#!/usr/bin/env bash
while [ $# -gt 0 ]; do
  if [ "$1" = "-o" ]; then echo "data" > "$2"; break; fi
  shift
done
MOCK
  chmod +x "$MOCK_DIR/curl"
  run download "https://example.com/file" "$MOCK_DIR/output"
  [ "$status" -eq 0 ]
}

@test "download falls back to wget when curl absent" {
  cat > "$MOCK_DIR/wget" << 'MOCK'
#!/bin/bash
while [ $# -gt 0 ]; do
  if [ "$1" = "-O" ]; then echo "data" > "$2"; break; fi
  shift
done
MOCK
  chmod +x "$MOCK_DIR/wget"

  run env PATH="$MOCK_DIR" /bin/bash -c "source '$INSTALL_LIB' && download https://example.com/file $MOCK_DIR/output"
  [ "$status" -eq 0 ]
}

@test "download exits 1 when no curl or wget available" {
  run env PATH="$MOCK_DIR" /bin/bash -c "source '$INSTALL_LIB' && download https://example.com/file /tmp/dest"
  [ "$status" -eq 1 ]
  [[ "$output" == *"curl or wget required"* ]]
}

@test "install_tool downloads from GitHub Releases when brew absent" {
  setup_github_release_mocks
  run install_tool
  [ "$status" -eq 0 ]
  [[ "$output" == *"Downloading guardrails"* ]]
  [[ "$output" == *"Installed guardrails"* ]]
  [[ "$output" == *"Add to your shell profile"* ]]
}

@test "install_tool falls back to GitHub Releases when brew fails" {
  setup_github_release_mocks
  cat > "$MOCK_DIR/brew" << 'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
  chmod +x "$MOCK_DIR/brew"
  run install_tool
  [ "$status" -eq 0 ]
  [[ "$output" == *"Homebrew install failed"* ]]
  [[ "$output" == *"Installed guardrails"* ]]
}

@test "install_tool exits non-zero when detect_platform fails" {
  mock_uname FreeBSD x86_64
  export PATH="$MOCK_DIR:/usr/bin:/bin"
  run install_tool
  [ "$status" -ne 0 ]
  [[ "$output" == *"Unsupported OS"* ]] || [[ "$output" == *"Error"* ]]
}

@test "install_tool exits non-zero when download fails" {
  mock_uname Darwin arm64
  cat > "$MOCK_DIR/curl" << 'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
  chmod +x "$MOCK_DIR/curl"
  export INSTALL_DIR="$MOCK_DIR/install"
  export PATH="$MOCK_DIR:/usr/bin:/bin"
  run install_tool
  [ "$status" -ne 0 ]
  [[ "$output" == *"Error"* ]] || [[ "$output" == *"failed"* ]]
}

@test "install_tool exits with error when TOOL is unset" {
  unset TOOL
  run install_tool
  [ "$status" -ne 0 ]
  [[ "$output" == *"TOOL must be set"* ]]
}

@test "install_tool exits with error when REPO is unset" {
  unset REPO
  run install_tool
  [ "$status" -ne 0 ]
  [[ "$output" == *"REPO must be set"* ]]
}

@test "install_tool exits non-zero when tar extraction fails" {
  mock_uname Darwin arm64
  cat > "$MOCK_DIR/curl" << 'MOCK'
#!/usr/bin/env bash
while [ $# -gt 0 ]; do
  if [ "$1" = "-o" ]; then touch "$2"; break; fi
  shift
done
MOCK
  chmod +x "$MOCK_DIR/curl"
  cat > "$MOCK_DIR/tar" << 'MOCK'
#!/usr/bin/env bash
exit 1
MOCK
  chmod +x "$MOCK_DIR/tar"
  export INSTALL_DIR="$MOCK_DIR/install"
  export PATH="$MOCK_DIR:/usr/bin:/bin"
  run install_tool
  [ "$status" -ne 0 ]
  [[ "$output" == *"extraction failed"* ]]
}

@test "install_tool exits non-zero when binary not found in tarball" {
  mock_uname Darwin arm64
  cat > "$MOCK_DIR/curl" << 'MOCK'
#!/usr/bin/env bash
while [ $# -gt 0 ]; do
  if [ "$1" = "-o" ]; then touch "$2"; break; fi
  shift
done
MOCK
  chmod +x "$MOCK_DIR/curl"
  cat > "$MOCK_DIR/tar" << 'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
  chmod +x "$MOCK_DIR/tar"
  export INSTALL_DIR="$MOCK_DIR/install"
  export PATH="$MOCK_DIR:/usr/bin:/bin"
  run install_tool
  [ "$status" -ne 0 ]
  [[ "$output" == *"binary not found in tarball"* ]]
}
