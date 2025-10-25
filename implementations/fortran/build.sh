#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

FC=${FC:-gfortran}
FFLAGS=${FFLAGS:--O3 -march=native}

if ! command -v "$FC" >/dev/null 2>&1; then
    echo "Error: Fortran compiler '$FC' not found. Install gfortran or set FC." >&2
    exit 1
fi

"$FC" $FFLAGS solution.f90 -o solution
