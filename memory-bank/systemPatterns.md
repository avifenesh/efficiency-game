# System Patterns

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Benchmark Orchestrator                    │
│                    (scripts/benchmark.sh)                    │
└───────────────────┬─────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        │                       │
        ▼                       ▼
┌───────────────┐       ┌──────────────────┐
│ Log Generator │       │ Measurement Tool │
│  (Python)     │       │  (/usr/bin/time) │
└───────────────┘       └──────────────────┘
        │                       │
        │                       ▼
        │               ┌──────────────────┐
        └──────────────►│  16 Language     │
                        │  Implementations │
                        └────────┬─────────┘
                                 │
                                 ▼
                        ┌──────────────────┐
                        │  results.json    │
                        └────────┬─────────┘
                                 │
                                 ▼
                        ┌──────────────────┐
                        │    Web UI        │
                        │ (HTML/CSS/JS)    │
                        └──────────────────┘
```

## Key Design Patterns

### 1. Language Implementation Pattern
Each language follows a standardized structure:

```
implementations/<language>/
├── solution.<ext>       # Core implementation
├── build.sh            # Compile script (if needed)
├── run.sh              # Execution wrapper
└── README.md           # Language-specific notes
```

**Standard Interface:**
- Input: Path to log file
- Output: JSON format: `{"errors": N, "warnings": N, "total": N}`
- Exit code: 0 on success

### 2. Measurement Pattern
```bash
# Warmup (1 iteration)
./run.sh <logfile> > /dev/null

# Measured runs (5 iterations)
for i in {1..5}; do
  /usr/bin/time -l ./run.sh <logfile> 2> metrics_$i.txt
done

# Parse and aggregate metrics
```

### 3. Data Flow Pattern

```
Synthetic Logs → Language Implementation → Raw Output
                                ↓
                         Measurement Tool
                                ↓
                    Time + Memory + CPU Metrics
                                ↓
                         JSON Aggregation
                                ↓
                         Web Visualization
```

## Component Relationships

### Log Generator
- **Responsibility**: Create reproducible test data
- **Output**: Fixed-format log files in `data/synthetic/`
- **Variability**: Controlled randomness with seed
- **Format**: `timestamp LEVEL [component] message`

### Language Implementations
- **Responsibility**: Process logs concurrently
- **Input**: Log file path as argument
- **Concurrency Models**:
  - **Thread-based**: C, C++, Java, Python (threading)
  - **Async/Await**: Node.js, Python (asyncio), C#, Rust (tokio)
  - **Actor Model**: Elixir
  - **Coroutines**: Kotlin, Go
  - **Process Pool**: Python (multiprocessing)
  - **Parallel Iterators**: Rust (rayon), Scala

### Benchmark Orchestrator
- **Responsibility**: Execute all implementations systematically
- **Flow**:
  1. Check for compiled languages, build if needed
  2. For each language:
     - Run warmup iteration
     - Run measured iterations
     - Collect metrics
  3. Aggregate results
  4. Generate results.json

### Measurement Tool
- **Tool**: `/usr/bin/time -l` (macOS BSD time)
- **Metrics Captured**:
  - Real time (wall clock)
  - User time (CPU in user space)
  - System time (CPU in kernel)
  - Maximum resident set size (peak memory)
  - CPU percentage
- **Format**: Parse text output into structured data

### Web UI
- **Architecture**: Static single-page application
- **Data Loading**: Fetch results.json on page load
- **Rendering**: Dynamic DOM manipulation
- **Visualization**: Chart.js or D3.js
- **Responsiveness**: CSS Grid/Flexbox

## Critical Implementation Paths

### Path 1: Compilation Required Languages
```
Source Code → Build Script → Binary → Run Script → Measurement
```
Languages: C, C++, Rust, Go, Zig, Nim, Mojo

### Path 2: JIT/VM Languages
```
Source Code → Runtime → Warmup → Measurement
```
Languages: Java, Kotlin, C#, Scala, Node.js

### Path 3: Interpreted Languages
```
Source Code → Interpreter → Direct Measurement
```
Languages: Python, Ruby, PHP, Perl, Elixir

## Concurrency Strategies

### File-Level Parallelism
- Split log file into chunks
- Process chunks concurrently
- Aggregate results

### Line-Level Parallelism
- Read file sequentially
- Process lines in parallel batches
- Maintain thread-safe counters

### Best Practices Per Language
- **C/C++**: Use pthreads or std::thread with mutex-protected counters
- **Rust**: Use rayon for data parallelism, tokio for async I/O
- **Java**: ExecutorService with thread pool
- **Python**: multiprocessing for CPU-bound work
- **Node.js**: Worker threads for blocking operations
- **Elixir**: Spawn processes for each chunk

## Error Handling

### Language Implementation Errors
- Non-zero exit code → Mark as failed in results
- Timeout (5 minutes) → Kill and mark as timeout
- Crash → Capture stderr, mark as crashed

### Measurement Errors
- Failed to parse metrics → Use placeholder values
- Missing output → Skip iteration
- Inconsistent results → Flag for review

## Performance Considerations

### Fair Comparison
- Same input data for all languages
- Same concurrency level (CPU cores available)
- Warmup for JIT languages
- Multiple iterations for statistical validity

### Resource Limits
- No artificial limits on memory/CPU
- Let each language use system resources naturally
- Monitor for resource exhaustion

## Data Formats

### Log File Format
```
2024-10-24 14:32:01 INFO [Service] Request processed successfully
2024-10-24 14:32:02 ERROR [Database] Connection timeout
```

### Output Format (per language)
```json
{
  "errors": 1000,
  "warnings": 2000,
  "total": 3000
}
```

### Results Format (aggregate)
```json
{
  "metadata": {
    "timestamp": "2024-10-24T14:32:01Z",
    "log_size": "medium",
    "iterations": 5
  },
  "languages": {
    "python": {
      "times": [1.23, 1.25, 1.22, 1.24, 1.23],
      "memory": [45.2, 45.5, 45.1, 45.3, 45.2],
      "cpu": [98.5, 98.7, 98.3, 98.6, 98.4],
      "stats": {
        "time_avg": 1.234,
        "time_min": 1.22,
        "time_max": 1.25,
        "memory_avg": 45.26
      }
    }
  }
}
```

## UI Component Architecture

### Components
1. **Header**: Title, description, metadata
2. **Leaderboard**: Sortable table with rankings
3. **Charts**: Bar race, comparison charts
4. **Details**: Per-language cards with metrics
5. **Footer**: Methodology notes

### State Management
- Load results.json once
- Store in memory
- Update UI reactively on sort/filter

### Visualization Strategy
- Animated entry of elements
- Smooth transitions between states
- Color coding by language category
- Responsive breakpoints
