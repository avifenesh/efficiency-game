#!/bin/bash
set -e
cd "$(dirname "$0")"

# Compile in optimized mode without debug info
kotlinc -include-runtime -Xno-call-assertions -Xno-param-assertions -d solution.jar Solution.kt
