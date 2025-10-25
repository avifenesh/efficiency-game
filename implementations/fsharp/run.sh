#!/bin/bash
# Run script for F# implementation

if [ $# -ne 1 ]; then
    echo "Usage: ./run.sh <logfile>" >&2
    exit 1
fi

LOGFILE="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

dotnet run --project "$SCRIPT_DIR/fsharp.fsproj" -c Release --no-build "$LOGFILE" 2>/dev/null
