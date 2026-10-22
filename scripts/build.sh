#!/usr/bin/env bash
# Build entry point for Odin-xmpp.
# Produces artifacts/xmpp_echo.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
mkdir -p artifacts

EXTRA_LDFLAGS=""
if [[ "$(uname -s)" == "Darwin" ]]; then
    # Include standard Homebrew library search path on macOS
    if [[ -d "/opt/homebrew/lib" ]]; then
        EXTRA_LDFLAGS="-extra-linker-flags:-L/opt/homebrew/lib"
    elif [[ -d "/usr/local/lib" ]]; then
        EXTRA_LDFLAGS="-extra-linker-flags:-L/usr/local/lib"
    fi
fi

echo "==> Building xmpp_echo into artifacts/xmpp_echo"
odin build cmd/xmpp_echo \
    -collection:xmpp=src \
    -collection:ffi=ffi \
    -out:artifacts/xmpp_echo \
    $EXTRA_LDFLAGS \
    -vet -strict-style

echo "==> Build succeeded: artifacts/xmpp_echo"
