#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

# Build the Carbon benchmark implementation (implemented via C++ reference backend)

CXX=${CXX:-clang++}
CXXFLAGS="-O3 -march=native -std=c++20 -pthread"

$CXX $CXXFLAGS solution.cpp -o solution
