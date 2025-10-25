#!/bin/bash
set -euo pipefail

# Run script for Lua implementation

if [ $# -ne 1 ]; then
    echo "Usage: ./run.sh <logfile>" >&2
    exit 1
fi

LOGFILE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

LUA_BIN=${LUA_BIN:-lua}

if ! command -v "$LUA_BIN" >/dev/null 2>&1; then
    echo "Lua not found. Please install Lua or set LUA_BIN." >&2
    exit 1
fi

"$LUA_BIN" "$SCRIPT_DIR/solution.lua" "$LOGFILE"
