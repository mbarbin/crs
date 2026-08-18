#!/bin/bash
# SPDX-FileCopyrightText: 2026 Mathieu Barbin <mathieu.barbin@gmail.com>
# SPDX-License-Identifier: MIT
# Install zola binary from GitHub releases.
#
# Environment variables:
#   ZOLA_VERSION     - required, e.g. "0.22.1"
#   ZOLA_DIGEST      - optional, e.g. "sha256:abc123..."
#   INSTALL_DIR      - optional, defaults to "$HOME/.local/bin"
#   BINARY_CACHE_HIT - optional, set to "true" to skip download (restored from cache)

set -euo pipefail

: "${ERRORPREFIX:="::error::Fatal error: "}"

abort() {
  printf '%s%s\n' "$ERRORPREFIX" "$1"
  exit 2
}

install_zola() {
  BIN_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
  mkdir -p "$BIN_DIR"

  if [ "${BINARY_CACHE_HIT:-}" = "true" ]; then
    echo "zola binary restored from cache"
    (set -x; "${BIN_DIR}/zola" --version)
    return
  fi

  case "$(uname -ms)" in
    'Linux x86_64')
      target=x86_64-unknown-linux-gnu
      ;;
    'Linux aarch64')
      target=aarch64-unknown-linux-gnu
      ;;
    'Darwin x86_64')
      target=x86_64-apple-darwin
      ;;
    'Darwin arm64')
      target=aarch64-apple-darwin
      ;;
    *)
      abort "Unsupported platform: $(uname -ms)"
      ;;
  esac

  local url="https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-${target}.tar.gz"
  local tmp_dir
  tmp_dir="$(mktemp -d)"

  (set -x;
    curl -fsSL "$url" | tar -xzf - -C "$tmp_dir"
    mv "$tmp_dir/zola" "$BIN_DIR/"
    "${BIN_DIR}/zola" --version)
  rm -rf "$tmp_dir"
}

verify_digest() {
  local binary="$1"
  local digest="$2"
  local algorithm="${digest%%:*}"
  local expected_hash="${digest#*:}"

  case "${algorithm}" in
    sha256)
      local actual_hash
      if command -v sha256sum >/dev/null 2>&1; then
        actual_hash=$(sha256sum "${binary}" | cut -d ' ' -f 1)
      elif command -v shasum >/dev/null 2>&1; then
        actual_hash=$(shasum -a 256 "${binary}" | cut -d ' ' -f 1)
      else
        abort "sha256sum or shasum is required to verify the binary digest"
      fi
      ;;
    *)
      abort "Digest algorithm '${algorithm}' is not supported. Supported: sha256"
      ;;
  esac

  if [ "${actual_hash}" != "${expected_hash}" ]; then
    abort "${algorithm}: expected ${expected_hash} but got ${actual_hash} for ${binary}"
  fi
  echo "Digest verified: ${algorithm}:${actual_hash}"
}

main() {
  if [ -z "${ZOLA_VERSION:-}" ]; then
    abort "ZOLA_VERSION is required"
  fi

  install_zola

  if [ -n "${ZOLA_DIGEST:-}" ]; then
    verify_digest "${BIN_DIR}/zola" "$ZOLA_DIGEST"
  fi
}

main
