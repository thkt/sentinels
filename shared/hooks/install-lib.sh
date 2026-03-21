#!/usr/bin/env bash
# Shared install functions for sentinels plugins.
# Usage: set TOOL and REPO, source this file, then call install_tool.

INSTALL_DIR="${INSTALL_DIR:-${HOME}/.local/bin}"

detect_platform() {
  local os arch
  os="$(uname -s)"
  arch="$(uname -m)"

  case "$os" in
    Darwin) os="apple-darwin" ;;
    Linux)  os="unknown-linux-gnu" ;;
    *) echo "Unsupported OS: $os" >&2; return 1 ;;
  esac

  case "$arch" in
    x86_64|amd64)  arch="x86_64" ;;
    arm64|aarch64) arch="aarch64" ;;
    *) echo "Unsupported architecture: $arch" >&2; return 1 ;;
  esac

  echo "${arch}-${os}"
}

download() {
  local url="$1" dest="$2"
  if command -v curl &>/dev/null; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget &>/dev/null; then
    wget -q "$url" -O "$dest"
  else
    echo "Error: curl or wget required" >&2
    return 1
  fi
}

install_tool() {
  : "${TOOL:?TOOL must be set}" "${REPO:?REPO must be set}"

  local tool_path
  if tool_path="$(command -v "$TOOL" 2>/dev/null)"; then
    echo "${TOOL} already installed: ${tool_path}"
    return
  fi

  if command -v brew &>/dev/null; then
    echo "Installing ${TOOL} via Homebrew..."
    if brew install "thkt/tap/${TOOL}"; then
      return
    fi
    echo "Homebrew install failed, falling back to GitHub Releases..." >&2
  fi

  local platform
  platform="$(detect_platform)" || { echo "Error: platform detection failed" >&2; return 1; }

  local asset="${TOOL}-${platform}.tar.gz"
  local url="https://github.com/${REPO}/releases/latest/download/${asset}"

  echo "Downloading ${TOOL} for ${platform}..."
  local tmpdir
  tmpdir="$(mktemp -d)"

  download "$url" "${tmpdir}/${asset}" || { rm -rf "$tmpdir"; echo "Error: download failed: ${url}" >&2; return 1; }
  tar xzf "${tmpdir}/${asset}" -C "$tmpdir" || { rm -rf "$tmpdir"; echo "Error: extraction failed" >&2; return 1; }
  [[ -f "${tmpdir}/${TOOL}" ]] || { rm -rf "$tmpdir"; echo "Error: ${TOOL} binary not found in tarball" >&2; return 1; }

  mkdir -p "$INSTALL_DIR"
  mv "${tmpdir}/${TOOL}" "${INSTALL_DIR}/${TOOL}"
  chmod +x "${INSTALL_DIR}/${TOOL}"
  rm -rf "$tmpdir"
  echo "Installed ${TOOL} to ${INSTALL_DIR}/${TOOL}"

  if [[ ":$PATH:" != *":${INSTALL_DIR}:"* ]]; then
    echo ""
    echo "Add to your shell profile:"
    echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
  fi
}
