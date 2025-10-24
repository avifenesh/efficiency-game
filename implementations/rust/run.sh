#!/bin/bash
set -e
cd "$(dirname "$0")"

LOG_FILE=${1:-"../../data/synthetic/medium.log"}

if [ ! -f "target/release/solution" ]; then
    ./build.sh > /dev/null
fi

./target/release/solution $LOG_FILE
