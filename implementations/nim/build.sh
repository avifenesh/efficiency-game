#!/bin/bash
set -e
cd "$(dirname "$0")"

# Maximum performance build with danger mode
nim c -d:danger --threads:on --opt:speed --passC:"-march=native -O3" solution.nim
