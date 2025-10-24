#!/bin/bash
set -e
cd "$(dirname "$0")"

nim c --threads:on -d:release solution.nim
