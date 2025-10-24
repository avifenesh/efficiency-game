#!/bin/bash
set -e
cd "$(dirname "$0")"

LOG_FILE=${1:-"../../data/synthetic/medium.log"}

if [ ! -f "bin/Release/net9.0/csharp.dll" ]; then
    ./build.sh > /dev/null
fi

dotnet bin/Release/net9.0/csharp.dll "$LOG_FILE"
