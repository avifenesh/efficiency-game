#!/bin/bash

# Run script for C3 implementation
# Executes the compiled C3 solution

cd "$(dirname "$0")"

# Check if solution exists
if [ ! -f "./solution" ]; then
    echo "Error: solution executable not found. Run build.sh first." >&2
    exit 1
fi

# Run the solution with the provided log file
./solution "$@"
