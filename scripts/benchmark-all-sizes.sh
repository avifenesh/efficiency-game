#!/bin/bash
# Run benchmarks across all dataset sizes (small, medium, large)
# and update the web dashboard with all results

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DATA_DIR="$PROJECT_ROOT/data"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================================"
echo "MULTI-SIZE BENCHMARK RUNNER"
echo "============================================================"
echo ""
echo "This will run benchmarks on all three dataset sizes:"
echo "  • Small   (10,000 lines)"
echo "  • Medium  (100,000 lines)"
echo "  • Large   (1,000,000 lines)"
echo ""

# Array of sizes to benchmark
SIZES=("small" "medium" "large")

for SIZE in "${SIZES[@]}"; do
    echo ""
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}Running benchmark for: ${SIZE}${NC}"
    echo -e "${BLUE}============================================================${NC}"
    echo ""
    
    # Check if log file exists
    LOG_FILE="$DATA_DIR/synthetic/${SIZE}.log"
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${YELLOW}⚠ Warning: Log file not found: $LOG_FILE${NC}"
        echo "Skipping $SIZE benchmark..."
        continue
    fi
    
    # Export the size so benchmark.sh can use it
    export BENCHMARK_SIZE="$SIZE"
    
    # Run the benchmark
    if "$SCRIPT_DIR/benchmark.sh"; then
        echo -e "${GREEN}✓ Completed ${SIZE} benchmark${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: ${SIZE} benchmark failed${NC}"
    fi
    
    # Brief pause between sizes
    sleep 3
done

echo ""
echo "============================================================"
echo "ALL BENCHMARKS COMPLETE"
echo "============================================================"
echo ""
echo "Results saved:"
echo "  • data/results-small.json"
echo "  • data/results-medium.json"
echo "  • data/results-large.json"
echo ""

# Update web dashboard with all results
echo "Updating web dashboard with all results..."
if python3 "$SCRIPT_DIR/update_web_all.py"; then
    echo -e "${GREEN}✓ Web dashboard updated: web/index.html${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Could not update web dashboard${NC}"
fi

echo ""
echo -e "${GREEN}✓ All benchmarks completed successfully!${NC}"
