#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: ./solution.sh <logfile>" >&2
    exit 1
fi

LOGFILE="$1"

if [ ! -f "$LOGFILE" ]; then
    echo "Error: File not found: $LOGFILE" >&2
    exit 1
fi

awk '
BEGIN {
    errors = 0;
    warnings = 0;
}
{
    if (index($0, "ERROR") && $0 ~ /(^|[^[:alnum:]])ERROR([^[:alnum:]]|$)/) {
        errors++;
    } else if (index($0, "WARN") && $0 ~ /(^|[^[:alnum:]])WARN([^[:alnum:]]|$)/) {
        warnings++;
    }
}
END {
    total = errors + warnings;
    printf("{\"errors\": %d, \"warnings\": %d, \"total\": %d}\n", errors, warnings, total);
}
' "$LOGFILE"
