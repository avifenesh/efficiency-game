# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Language Efficiency Race is a comprehensive benchmark comparing the execution efficiency of multiple programming languages through a real-world concurrent log anomaly detection task. Each language implementation processes log files to detect and count ERROR and WARN patterns using language-native concurrency features.

**Current Status**: 3/16 languages implemented (C, Node.js, Python)

## Common Commands

### Generate Synthetic Logs
```bash
python3 scripts/generate_logs.py
```
Creates three log file sizes in `data/synthetic/`:
- `small.log`: 10K lines (~1 MB)
- `medium.log`: 100K lines (~10 MB)
- `large.log`: 1M lines (~100 MB)

Log distribution: 70% INFO, 20% WARN, 10% ERROR

### Run Benchmark
```bash
chmod +x scripts/benchmark.sh
./scripts/benchmark.sh
```
- Builds all compiled language implementations
- Runs warmup iterations for JIT languages
- Executes 5 measured iterations per language
- Collects time, memory, and CPU metrics via `/usr/bin/time -l`
- Generates `data/results.json`
- **Automatically updates `web/index.html` with latest results**

### View Results
```bash
open web/index.html
```

The web page is automatically updated after each benchmark run via `scripts/update_web.py`.

## High-Level Architecture

### Standard Implementation Interface
Every language implementation must follow this contract:

**Directory Structure:**
```
implementations/<language>/
├── solution.<ext>      # Core implementation
├── build.sh            # Compilation script (if compiled language)
└── run.sh              # Execution wrapper
```

**Input/Output Contract:**
```bash
# Input
./run.sh <path_to_log_file>

# Output (JSON to stdout)
{"errors": 123, "warnings": 456, "total": 579}

# Exit code: 0 on success, non-zero on failure
```

### Concurrency Strategy
Each implementation must use the language's native concurrency model to process log files in parallel:

- **C**: pthreads with mutex-protected counters
- **Python**: multiprocessing.Pool (10K line chunks)
- **Node.js**: worker_threads with CPU core count workers
- **Future implementations**: Thread-based (C++, Java), async/await (Rust, C#), actor model (Elixir), coroutines (Kotlin, Go), etc.

Key requirement: Split the log file into chunks and process concurrently, then aggregate results.

### Pattern Matching Requirements
Implementations must detect ERROR and WARN as **whole words only** (word boundary matching). Both Python and Node.js use a `contains_word()` function that checks alphanumeric boundaries to ensure patterns like "ERRORED" don't match "ERROR".

Example from C implementation:
```c
// Checks that word is surrounded by non-alphanumeric characters
int contains_word(const char *line, const char *word)
```

### Measurement System
The benchmark uses macOS `/usr/bin/time -l` to capture:
- Real time (wall clock)
- User time (CPU in user space)
- System time (CPU in kernel)
- Maximum resident set size (peak memory in bytes)
- CPU utilization percentage

The orchestrator runs:
1. Warmup iteration (for JIT languages, discarded)
2. 5 measured iterations
3. Statistical aggregation (min, max, avg)

### Results Format
```json
{
  "metadata": {
    "timestamp": "ISO-8601",
    "log_size": "medium",
    "iterations": 5
  },
  "languages": {
    "python": {
      "times": [1.23, 1.25, ...],
      "memory": [45.2, 45.5, ...],
      "cpu": [98.5, 98.7, ...],
      "stats": {
        "time_avg": 1.234,
        "memory_avg": 45.26,
        "cpu_avg": 98.5
      }
    }
  }
}
```

## Adding New Language Implementations

When implementing a new language:

1. **Create directory structure**: `implementations/<language>/`
2. **Implement solution**: Read log file, use concurrency to process chunks, detect ERROR/WARN with word boundaries, output JSON
3. **Create run.sh**: Script that accepts log file path as argument
4. **Create build.sh** (if compiled): Build script optimized for performance (-O3 flags, release mode)
5. **Add to benchmark.sh**: Update LANGUAGES array with format `"name:needs_build:needs_warmup:run_command"`
6. **Test locally**: Verify output format matches exactly and exit code is 0 on success

### Performance Optimization Tips
- Use release/optimized builds (C: `-O3`, Rust: `--release`, etc.)
- Leverage all CPU cores (use `os.cpu_count()`, `sysconf(_SC_NPROCESSORS_ONLN)`, etc.)
- Minimize I/O overhead (read file once, split in memory)
- For compiled languages, ensure binaries are in `.gitignore`

## Web Visualization

The web UI (`web/index.html`) is a static single-page application that:
- Loads `data/results.json` (or embedded data to avoid CORS)
- Displays interactive charts using Chart.js
- Shows leaderboard sorted by execution time
- Uses dark theme with language-specific colors defined in `LANGUAGE_COLORS`

No build step required; open directly in browser.

## Project Context

This benchmark addresses the common question "Which programming language is fastest?" using a realistic concurrent log processing scenario instead of artificial microbenchmarks. The goal is educational: demonstrate language performance characteristics, concurrency models, and trade-offs between speed, memory usage, and development complexity.

Target platform: macOS only (uses BSD-specific `/usr/bin/time -l` flags)

## Memory Bank

The `memory-bank/` directory contains detailed project documentation:
- `projectbrief.md`: Project goals and deliverables
- `productContext.md`: Why the project exists and expected performance tiers
- `systemPatterns.md`: Detailed architecture patterns and data flows
- `techContext.md`: Language-specific dependencies and installation instructions
- `activeContext.md`: Current work state
- `progress.md`: Implementation progress tracking

Consult these files for deeper understanding of design decisions and implementation strategies.
