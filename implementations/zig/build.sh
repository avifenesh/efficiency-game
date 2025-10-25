#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Build the Zig benchmark implementation

ZIG_BIN=${ZIG_BIN:-zig}

if ! command -v "$ZIG_BIN" >/dev/null 2>&1; then
    echo "Zig toolchain not found. Please install Zig or set ZIG_BIN." >&2
    exit 1
fi

"$ZIG_BIN" build-exe solution.zig -O ReleaseFast -femit-bin=solution
