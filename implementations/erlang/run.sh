#!/bin/bash
set -euo pipefail

# Run script for Erlang implementation

if [ $# -ne 1 ]; then
    echo "Usage: ./run.sh <logfile>" >&2
    exit 1
fi

LOGFILE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ESCRIPT_BIN=${ESCRIPT_BIN:-escript}

if ! command -v "$ESCRIPT_BIN" >/dev/null 2>&1; then
    echo "Erlang escript not found. Please install Erlang or set ESCRIPT_BIN." >&2
    exit 1
fi

"$ESCRIPT_BIN" "$SCRIPT_DIR/solution.erl" "$LOGFILE"
