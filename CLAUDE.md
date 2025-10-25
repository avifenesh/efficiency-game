# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a multi-language benchmark project that compares execution efficiency across 13+ programming languages using a real-world concurrent log anomaly detection task. Each implementation processes log files to count ERROR and WARN patterns using language-native concurrency mechanisms.

## Essential Commands

### Generate Test Data
```bash
python3 scripts/generate_logs.py
```
Creates three log file sizes:
- `data/synthetic/small.log`: 10K lines (~1 MB)
- `data/synthetic/medium.log`: 100K lines (~10 MB)
- `data/synthetic/large.log`: 1M lines (~100 MB)

### Run Full Benchmark
```bash
chmod +x scripts/benchmark.sh
./scripts/benchmark.sh
```
Runs all language implementations with 15 measured iterations, collects metrics, generates `data/results.json`, and automatically updates `web/index.html`.

### Run Single Language Implementation
```bash
cd implementations/<language>
./build.sh  # if needed (compiled languages)
./run.sh /path/to/logfile.log
```

### Publish to GitHub Pages
```bash
python3 scripts/publish_docs.py
```
Copies `web/` to `docs/` for GitHub Pages deployment.

### View Dashboard
```bash
open web/index.html
```

## Architecture

### Implementation Standard Interface

All language implementations follow a strict contract:

**Input**: `./run.sh <path_to_log_file>`

**Output** (JSON to stdout):
```json
{"errors": 123, "warnings": 456, "total": 579}
```

**Exit code**: 0 on success, non-zero on failure

### Directory Structure

```
implementations/
├── <language>/
│   ├── solution.<ext>      # Main implementation
│   ├── build.sh            # Compile script (if needed)
│   └── run.sh              # Execution wrapper (required)
```

Each implementation:
1. Reads log files using concurrent/parallel processing
2. Scans for ERROR and WARN patterns with word boundary matching
3. Counts total occurrences
4. Outputs JSON result

### Benchmark Orchestration

`scripts/benchmark.sh` controls all benchmarking:
- **Configuration**: Edit `LOG_SIZE`, `ITERATIONS`, `WARMUP_RUNS`, `COOLDOWN_SECONDS` at the top
- **Language registry**: `LANGUAGES` array defines which languages to test
- **Format**: `"name:needs_build:needs_warmup:run_command"`
- **Metrics collected**: Real time, user time, system time, max resident memory, CPU %
- **Dependencies**: Uses macOS `/usr/bin/time -l` for metrics collection

### Web Dashboard Updates

After benchmarking, `scripts/update_web.py` automatically:
1. Reads `data/results.json`
2. Updates embedded `window.BENCHMARK_DATA` in `web/index.html`
3. Syncs to `docs/index.html` if using GitHub Pages

## Adding a New Language

1. Create `implementations/<language>/` directory
2. Implement `solution.<ext>` following the standard interface
3. Create `run.sh` (always required)
4. Create `build.sh` if compilation is needed
5. Add language to `LANGUAGES` array in `scripts/benchmark.sh`:
   ```bash
   "<language>:yes:no:./solution"  # compiled, no warmup
   "<language>:no:yes:interpreter"  # interpreted, needs warmup
   ```
6. Run `./scripts/benchmark.sh` to verify

## Language-Specific Implementation Patterns

### Python (`implementations/python/solution.py`)
- Uses `multiprocessing.Pool` with CPU core count
- Binary mode I/O to avoid UTF-8 overhead
- Chunk size: 20K lines per chunk
- Pattern matching via byte string word boundary checks

### C (`implementations/c/solution.c`)
- Uses `pthreads` with `sysconf(_SC_NPROCESSORS_ONLN)` threads
- Manual `strstr()` with word boundary validation
- Builds with: `clang -O3 -pthread -o solution solution.c`
- Memory management: explicit `malloc`/`free`, `strdup`

### Rust (`implementations/rust/`)
- Uses `rayon` for data parallelism
- Build with: `cargo build --release`
- Aggressive optimization flags in `Cargo.toml`:
  ```toml
  opt-level = 3
  lto = "fat"
  codegen-units = 1
  ```

### JIT Languages (Java, C#, Kotlin, Node.js)
- Configured with `needs_warmup:yes` in benchmark.sh
- Run 1+ warmup iterations before measurement

## Key Benchmarking Details

- **Pattern matching**: Must enforce word boundaries (e.g., "ERROR" matches, "ERRORS" does not)
- **Concurrency required**: Implementations should use language-native parallelism
- **Fairness**: Same input data, sequential execution, warmup for JIT, 2s cooldown between iterations
- **Measurement**: 15 iterations with min/max/avg/median statistics

## Development Conventions

- Keep language implementations isolated under `implementations/`
- Avoid cross-cutting changes across multiple language directories
- Each implementation should be idiomatic to its language
- `run.sh` scripts use minimal dependencies and explicit paths
- Benchmark harness changes affect all languages—document carefully

## Important Notes from Copilot Instructions

- The repository demonstrates direct, idiomatic implementations per language rather than a single shared library
- Data files (`data/synthetic/*.log`, `data/results.json`) are canonical—do not hard-code paths
- C code expects explicit allocation/free and careful pthread usage
- No heavy external package manifests—assume standard runtimes
- Document major changes in `memory-bank/progress.md` and `README.md`
