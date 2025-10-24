#!/bin/bash
set -e
cd "$(dirname "$0")"

g++ -std=c++11 -pthread -O3 -o solution solution.cpp
