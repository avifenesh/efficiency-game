#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

LOG_FILE=${1:-"../../data/synthetic/medium.log"}

if [ ! -x "solution" ]; then
  ./build.sh
fi

./solution "$LOG_FILE"
