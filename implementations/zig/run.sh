#!/bin/bash
set -euo pipefail

# Run script for Zig implementation

if [ $# -ne 1 ]; then
    echo "Usage: ./run.sh <logfile>" >&2
    exit 1
fi

LOGFILE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ ! -x "$SCRIPT_DIR/solution" ]; then
    "$SCRIPT_DIR/build.sh"
fi

"$SCRIPT_DIR/solution" "$LOGFILE"
