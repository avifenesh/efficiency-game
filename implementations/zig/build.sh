#!/bin/bash
set -e
cd "$(dirname "$0")"

# Note: Optimization flags cause compiler crash on some Zig versions
# Building without optimization for compatibility
zig build-exe solution.zig
