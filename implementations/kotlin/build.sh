#!/bin/bash
set -e
cd "$(dirname "$0")"

kotlinc Solution.kt -include-runtime -d solution.jar
