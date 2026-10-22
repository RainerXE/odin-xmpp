#!/usr/bin/env bash
# Test entry point for Odin-xmpp.
# Runs unit tests under tracking allocator to verify zero leaks and correctness.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p artifacts

EXTRA_LDFLAGS=""
if [[ "$(uname -s)" == "Darwin" ]]; then
    if [[ -d "/opt/homebrew/lib" ]]; then
        EXTRA_LDFLAGS="-extra-linker-flags:-L/opt/homebrew/lib"
    elif [[ -d "/usr/local/lib" ]]; then
        EXTRA_LDFLAGS="-extra-linker-flags:-L/usr/local/lib"
    fi
fi

echo "==> Running unit tests in src/xmpp"
odin test src/xmpp \
    -collection:ffi=ffi \
    -out:artifacts/xmpp_test \
    $EXTRA_LDFLAGS \
    -vet -strict-style

echo "==> All tests passed"
