#!/bin/bash
# Benchmark Orchestrator
# Runs all language implementations and collects performance metrics

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IMPL_DIR="$PROJECT_ROOT/implementations"
DATA_DIR="$PROJECT_ROOT/data"
RESULTS_FILE="$DATA_DIR/results.json"

# Configuration
LOG_SIZE="medium"  # small, medium, or large
LOG_FILE="$DATA_DIR/synthetic/${LOG_SIZE}.log"
ITERATIONS=10
WARMUP_RUNS=1
COOLDOWN_SECONDS=2
TIMEOUT=300  # 5 minutes

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "============================================================"
echo "LANGUAGE EFFICIENCY BENCHMARK"
echo "============================================================"
echo ""
echo "Configuration:"
echo "  Log file: $LOG_FILE"
echo "  Iterations: $ITERATIONS"
echo "  Warmup runs: $WARMUP_RUNS"
echo "  Cooldown: ${COOLDOWN_SECONDS}s"
echo "  Timeout: ${TIMEOUT}s"
echo ""

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo -e "${RED}Error: Log file not found. Run generate_logs.py first.${NC}"
    exit 1
fi

# Language configurations
# Format: "name:needs_build:needs_warmup:run_command"
declare -a LANGUAGES=(
    "bash:no:no:bash"
    "python:no:no:python3"
    "nodejs:no:yes:node"
    "c:yes:no:./solution"
    "cpp:yes:no:./solution"
    "c3:yes:no:./solution"
    "carbon:yes:no:./solution"
    "rust:yes:no:./solution"
    "java:yes:yes:java"
    "kotlin:yes:yes:java"
    "csharp:yes:no:dotnet"
    "fsharp:yes:yes:dotnet"
    "julia:no:yes:julia"
    "elixir:no:yes:elixir"
    "ruby:no:no:ruby"
    "nim:yes:no:./solution"
    "php:no:no:php"
    "perl:no:no:perl"
    "fortran:yes:no:./solution"
    "ocaml:yes:no:./solution"
    "assembly:yes:no:./solution"
)

# Initialize results
echo "{" > "$RESULTS_FILE"
echo "  \"metadata\": {" >> "$RESULTS_FILE"
echo "    \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"," >> "$RESULTS_FILE"
echo "    \"log_size\": \"$LOG_SIZE\"," >> "$RESULTS_FILE"
echo "    \"iterations\": $ITERATIONS" >> "$RESULTS_FILE"
echo "  }," >> "$RESULTS_FILE"
echo "  \"languages\": {" >> "$RESULTS_FILE"

FIRST_LANG=true

for lang_config in "${LANGUAGES[@]}"; do
    IFS=':' read -r LANG NEEDS_BUILD NEEDS_WARMUP RUN_CMD <<< "$lang_config"
    
    LANG_DIR="$IMPL_DIR/$LANG"
    
    echo "------------------------------------------------------------"
    echo "Testing: $LANG"
    echo "------------------------------------------------------------"
    
    # Check if implementation exists
    if [ ! -d "$LANG_DIR" ]; then
        echo -e "${YELLOW}⊘ Skipped (not implemented)${NC}"
        continue
    fi
    
    # Build if needed
    if [ "$NEEDS_BUILD" = "yes" ]; then
        if [ -f "$LANG_DIR/build.sh" ]; then
            echo "Building..."
            cd "$LANG_DIR"
            if ! ./build.sh > /dev/null 2>&1; then
                echo -e "${RED}✗ Build failed${NC}"
                continue
            fi
            cd "$PROJECT_ROOT"
            echo -e "${GREEN}✓ Build successful${NC}"
        fi
    fi
    
    # Verify run script exists
    if [ ! -f "$LANG_DIR/run.sh" ]; then
        echo -e "${RED}✗ No run.sh found${NC}"
        continue
    fi
    
    # Warmup phase
    if [ "$WARMUP_RUNS" -gt 0 ]; then
        echo "Running warmup ($WARMUP_RUNS run(s))..."
        for w in $(seq 1 $WARMUP_RUNS); do
            timeout $TIMEOUT "$LANG_DIR/run.sh" "$LOG_FILE" > /dev/null 2>&1 || true
        done
    fi
    
    # Run measured iterations
    declare -a TIMES=()
    declare -a MEMORIES=()
    declare -a CPUS=()
    
    SUCCESS=true
    
    for i in $(seq 1 $ITERATIONS); do
        echo -n "  Iteration $i/$ITERATIONS... "
        
        TEMP_FILE=$(mktemp)
        
        if timeout $TIMEOUT /usr/bin/time -l "$LANG_DIR/run.sh" "$LOG_FILE" > /dev/null 2> "$TEMP_FILE"; then
            # Parse metrics from /usr/bin/time output
            REAL_TIME=$(grep "real" "$TEMP_FILE" | awk '{print $1}' || echo "0")
            USER_TIME=$(grep "user" "$TEMP_FILE" | awk '{print $1}' || echo "0")
            SYS_TIME=$(grep "sys" "$TEMP_FILE" | awk '{print $1}' || echo "0")
            MAX_MEM=$(grep "maximum resident set size" "$TEMP_FILE" | awk '{print $1}' || echo "0")
            
            # Calculate CPU percentage: ((user + sys) / real) * 100
            if [ "$REAL_TIME" != "0" ] && [ "$REAL_TIME" != "0.00" ]; then
                CPU_PCT=$(echo "scale=1; ($USER_TIME + $SYS_TIME) / $REAL_TIME * 100" | bc)
            else
                CPU_PCT="0"
            fi
            
            # Convert memory from bytes to MB
            MEM_MB=$(echo "scale=2; $MAX_MEM / 1024 / 1024" | bc)
            
            TIMES+=("$REAL_TIME")
            MEMORIES+=("$MEM_MB")
            CPUS+=("$CPU_PCT")
            
            echo -e "${GREEN}✓${NC} (${REAL_TIME}s, ${MEM_MB}MB)"
        else
            echo -e "${RED}✗ Failed${NC}"
            SUCCESS=false
            break
        fi
        
        rm -f "$TEMP_FILE"
        if [ "$COOLDOWN_SECONDS" -gt 0 ] && [ "$i" -lt "$ITERATIONS" ]; then
            sleep $COOLDOWN_SECONDS
        fi
    done

    if [ "$COOLDOWN_SECONDS" -gt 0 ]; then
        echo "Cooldown for ${COOLDOWN_SECONDS}s..."
        sleep $COOLDOWN_SECONDS
    fi
    
    if [ "$SUCCESS" = true ]; then
        # Calculate statistics
        AVG_TIME=$(echo "${TIMES[@]}" | tr ' ' '\n' | awk '{s+=$1} END {printf "%.3f", s/NR}')
        AVG_MEM=$(echo "${MEMORIES[@]}" | tr ' ' '\n' | awk '{s+=$1} END {printf "%.2f", s/NR}')
        AVG_CPU=$(echo "${CPUS[@]}" | tr ' ' '\n' | awk '{s+=$1} END {printf "%.1f", s/NR}')
        
        # Add comma if not first language
        if [ "$FIRST_LANG" = false ]; then
            echo "," >> "$RESULTS_FILE"
        fi
        FIRST_LANG=false
        
        # Write results
        echo "    \"$LANG\": {" >> "$RESULTS_FILE"
        echo "      \"times\": [$(IFS=,; echo "${TIMES[*]}")]," >> "$RESULTS_FILE"
        echo "      \"memory\": [$(IFS=,; echo "${MEMORIES[*]}")]," >> "$RESULTS_FILE"
        echo "      \"cpu\": [$(IFS=,; echo "${CPUS[*]}")]," >> "$RESULTS_FILE"
        echo "      \"stats\": {" >> "$RESULTS_FILE"
        echo "        \"time_avg\": $AVG_TIME," >> "$RESULTS_FILE"
        echo "        \"memory_avg\": $AVG_MEM," >> "$RESULTS_FILE"
        echo "        \"cpu_avg\": $AVG_CPU" >> "$RESULTS_FILE"
        echo "      }" >> "$RESULTS_FILE"
        echo -n "    }" >> "$RESULTS_FILE"
        
        echo ""
        echo -e "${GREEN}✓ Complete${NC} - Avg: ${AVG_TIME}s, ${AVG_MEM}MB, ${AVG_CPU}% CPU"
    fi
    
    echo ""
done

# Close JSON
echo "" >> "$RESULTS_FILE"
echo "  }" >> "$RESULTS_FILE"
echo "}" >> "$RESULTS_FILE"

echo "============================================================"
echo "BENCHMARK COMPLETE"
echo "Results saved to: $RESULTS_FILE"
echo "============================================================"
echo ""

# Update web page with latest results
echo "Updating web page..."
if python3 "$SCRIPT_DIR/update_web.py"; then
    echo -e "${GREEN}✓ Web page updated${NC}"
    echo ""
    echo "View results: open web/index.html"
else
    echo -e "${YELLOW}⚠ Warning: Could not update web page${NC}"
fi
