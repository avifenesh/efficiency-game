#!/bin/bash

# Build script for C3 implementation
# Requires c3c compiler to be installed

set -e

cd "$(dirname "$0")"

# Check if c3c is available
if ! command -v c3c &> /dev/null; then
    echo "Error: c3c compiler not found. Please install C3 from https://c3-lang.org/"
    exit 1
fi

# Compile the C3 solution with optimizations
echo "Compiling C3 solution..."
c3c compile -O5 --output-dir . solution.c3

# Make the output executable
chmod +x solution

echo "Build completed successfully"
