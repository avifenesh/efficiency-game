#!/bin/bash
set -e
cd "$(dirname "$0")"

LOG_FILE=${1:-"../../data/synthetic/medium.log"}

if [ ! -f "solution" ]; then
    ./build.sh > /dev/null
fi

./solution "$LOG_FILE"
