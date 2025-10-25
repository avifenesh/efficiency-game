#!/bin/bash
# Build script for OCaml implementation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Building OCaml implementation..."

# Try to build with Domainslib support first
if ocamlfind query domainslib > /dev/null 2>&1; then
    echo "Building with Domainslib (parallel)..."
    ocamlfind ocamlopt -package domainslib -linkpkg -o solution solution.ml 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "✓ Build successful (with parallel support)"
        exit 0
    fi
fi

# Fallback to simple sequential build
echo "Building sequential version..."
ocamlopt -o solution solution.ml 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ Build successful (sequential)"
    exit 0
else
    echo "✗ Build failed"
    exit 1
fi
