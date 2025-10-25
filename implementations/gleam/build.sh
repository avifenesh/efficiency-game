#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Build the Gleam benchmark implementation

GLEAM_BIN=${GLEAM_BIN:-gleam}

if ! command -v "$GLEAM_BIN" >/dev/null 2>&1; then
    echo "Gleam toolchain not found. Please install Gleam or set GLEAM_BIN." >&2
    exit 1
fi

# Build the project
"$GLEAM_BIN" build
