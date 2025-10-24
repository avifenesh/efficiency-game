#!/bin/bash
set -e
cd "$(dirname "$0")"

# Compile without debug info for production
javac -g:none Solution.java
