#!/bin/sh
# SPDX-FileCopyrightText: 2026 Mathieu Barbin <mathieu.barbin@gmail.com>
# SPDX-License-Identifier: MIT
# Test the zola install script locally.
# Usage: ./test-install-zola.sh <version> <digest>
set -eu

if [ $# -ne 2 ]; then
  echo "Usage: $0 <zola-version> <zola-digest>" >&2
  exit 1
fi

BINARY="zola"
FAKE_TMPDIR="$(mktemp -d)"
trap 'rm -rf "${FAKE_TMPDIR}"' EXIT

export ZOLA_VERSION="$1"
export ZOLA_DIGEST="$2"
export INSTALL_DIR="${FAKE_TMPDIR}/bin"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "${SCRIPT_DIR}/install-zola.sh"

if [ -x "${INSTALL_DIR}/${BINARY}" ]; then
  echo "${BINARY} binary installed successfully at ${INSTALL_DIR}/${BINARY}"
  "${INSTALL_DIR}/${BINARY}" --version
else
  echo "Error: ${BINARY} binary was not installed in ${INSTALL_DIR}/" >&2
  exit 1
fi
