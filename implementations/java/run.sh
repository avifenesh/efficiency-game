#!/bin/bash
set -e
cd "$(dirname "$0")"

LOG_FILE=${1:-"../../data/synthetic/medium.log"}

if [ ! -f "Solution.class" ]; then
    ./build.sh > /dev/null
fi

java Solution $LOG_FILE
