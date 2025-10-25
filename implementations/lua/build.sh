#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Build script for Lua implementation
# Lua is interpreted, but we need to check dependencies

LUA_BIN=${LUA_BIN:-lua}

if ! command -v "$LUA_BIN" >/dev/null 2>&1; then
    echo "Lua not found. Please install Lua or set LUA_BIN." >&2
    exit 1
fi

# Check for required LuaRocks packages
echo "Checking Lua dependencies..."

if ! "$LUA_BIN" -e "require('lanes')" 2>/dev/null; then
    echo "Warning: lanes library not found. Install with: luarocks install lanes" >&2
fi

if ! "$LUA_BIN" -e "require('dkjson')" 2>/dev/null; then
    echo "Warning: dkjson library not found. Install with: luarocks install dkjson" >&2
fi

echo "Lua implementation ready"
