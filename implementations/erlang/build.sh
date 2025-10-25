#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Build script for Erlang implementation
# Erlang is interpreted via escript, so we just check for escript

ESCRIPT_BIN=${ESCRIPT_BIN:-escript}

if ! command -v "$ESCRIPT_BIN" >/dev/null 2>&1; then
    echo "Erlang escript not found. Please install Erlang or set ESCRIPT_BIN." >&2
    exit 1
fi

echo "Erlang implementation ready"
