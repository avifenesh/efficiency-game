#!/bin/bash
set -e
cd "$(dirname "$0")"

LOG_FILE=${1:-"../../data/synthetic/medium.log"}

# Use scala run command which handles classpath automatically
scala run Solution.scala -- "$LOG_FILE" 2>&1 | grep -v "WARNING:"
