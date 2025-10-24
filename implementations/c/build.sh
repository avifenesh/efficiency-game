#!/bin/bash
# Build script for C implementation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building C implementation..."
clang -O3 -pthread -o solution solution.c

if [ $? -eq 0 ]; then
    echo "✓ Build successful"
    exit 0
else
    echo "✗ Build failed"
    exit 1
fi
