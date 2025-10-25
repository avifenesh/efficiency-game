#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Build the Go benchmark implementation

GO_BIN=${GO_BIN:-go}

if ! command -v "$GO_BIN" >/dev/null 2>&1; then
    echo "Go toolchain not found. Please install Go or set GO_BIN." >&2
    exit 1
fi

"$GO_BIN" build -o solution solution.go
