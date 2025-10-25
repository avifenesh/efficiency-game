#!/bin/bash
set -euo pipefail

# Run script for Common Lisp (SBCL) implementation

if [ $# -ne 1 ]; then
    echo "Usage: ./run.sh <logfile>" >&2
    exit 1
fi

LOGFILE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SBCL_BIN=${SBCL_BIN:-sbcl}

if ! command -v "$SBCL_BIN" >/dev/null 2>&1; then
    echo "SBCL not found. Please install SBCL or set SBCL_BIN." >&2
    exit 1
fi

"$SBCL_BIN" --script "$SCRIPT_DIR/solution.lisp" "$LOGFILE"
