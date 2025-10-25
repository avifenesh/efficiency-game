#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Build script for Common Lisp (SBCL) implementation
# Lisp is interpreted/compiled dynamically, so we just check for SBCL

SBCL_BIN=${SBCL_BIN:-sbcl}

if ! command -v "$SBCL_BIN" >/dev/null 2>&1; then
    echo "SBCL (Steel Bank Common Lisp) not found. Please install SBCL or set SBCL_BIN." >&2
    exit 1
fi

echo "SBCL implementation ready"
