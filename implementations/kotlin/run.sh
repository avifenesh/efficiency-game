#!/bin/bash
set -e
cd "$(dirname "$0")"

LOG_FILE=${1:-"../../data/synthetic/medium.log"}

if [ ! -f "solution.jar" ]; then
    ./build.sh > /dev/null
fi

java -jar solution.jar $LOG_FILE
