#!/bin/bash
set -e
cd "$(dirname "$0")"

LOG_FILE=${1:-"../../data/synthetic/medium.log"}

if [ ! -f "bin/Release/net6.0/csharp" ]; then
    ./build.sh > /dev/null
fi

./bin/Release/net6.0/csharp $LOG_FILE
