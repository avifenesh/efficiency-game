#!/bin/bash
# Build script for F# implementation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building F# implementation..."
dotnet build -c Release > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo "✓ Build successful"
    exit 0
else
    echo "✗ Build failed"
    exit 1
fi
