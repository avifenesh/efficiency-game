#!/bin/bash
# Build script for Assembly-style implementation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building Assembly-style implementation..."

# Low-level C implementation with assembly-like optimizations
if [ -f solution.c ]; then
    clang -O3 -march=native -fno-unroll-loops -o solution solution.c

    if [ $? -eq 0 ]; then
        echo "✓ Build successful"
        exit 0
    else
        echo "✗ Build failed"
        exit 1
    fi
fi

echo "✗ Build failed"
exit 1
