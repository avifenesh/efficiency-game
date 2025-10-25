#!/bin/bash
set -euo pipefail

# Run script for Gleam implementation

if [ $# -ne 1 ]; then
    echo "Usage: ./run.sh <logfile>" >&2
    exit 1
fi

LOGFILE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GLEAM_BIN=${GLEAM_BIN:-gleam}

if ! command -v "$GLEAM_BIN" >/dev/null 2>&1; then
    echo "Gleam not found. Please install Gleam or set GLEAM_BIN." >&2
    exit 1
fi

cd "$SCRIPT_DIR"
"$GLEAM_BIN" run -- "$LOGFILE"
