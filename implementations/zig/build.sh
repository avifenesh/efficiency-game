#!/bin/bash
set -e
cd "$(dirname "$0")"

zig build-exe solution.zig -O ReleaseSafe
