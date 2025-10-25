#!/bin/bash
# Build script for Perl implementation (checks dependencies)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "Checking Perl dependencies..."

# Check if threads are available (built-in for most Perl installations)
perl -e 'use threads; use threads::shared;' 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ Perl threads support available"
else
    echo "⚠ Warning: Perl threads not available, will use sequential processing"
fi

# Check for JSON::PP (optional, will fallback to manual JSON)
perl -e 'use JSON::PP;' 2>/dev/null
if [ $? -eq 0 ]; then
    echo "✓ JSON::PP available"
else
    echo "ℹ JSON::PP not available, using manual JSON generation"
fi

exit 0
