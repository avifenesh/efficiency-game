#!/bin/bash
set -e
cd "$(dirname "$0")"

g++ -std=c++11 -pthread -o solution solution.cpp
