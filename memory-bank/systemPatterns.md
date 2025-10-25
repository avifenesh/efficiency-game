# System Patterns: Language Efficiency Race

## System Architecture

### High-Level Overview
```
┌─────────────────────────────────────────────────────────────┐
│                    Benchmark Pipeline                        │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  generate_logs.py → [Log Files] → benchmark.sh →            │
│                                    ↓                          │
│                          Language Implementations            │
│                                    ↓                          │
│                         [results.json] → update_web.py →     │
│                                          ↓                    │
│                                  [web/index.html]            │
│                                          ↓                    │
│                                  publish_docs.py →           │
│                                          ↓                    │
│                               [docs/] → GitHub Pages         │
└─────────────────────────────────────────────────────────────┘
```

## Core Design Patterns

### 1. Standard Implementation Interface

**Pattern**: All language implementations follow identical contract

**Structure**:
```
implementations/<language>/
├── solution.<ext>        # Main implementation
├── run.sh               # Execution wrapper (executable)
└── build.sh            # Build script (if compiled)
```

**Interface Contract**:
```bash
# Input
./run.sh <path_to_log_file>

# Output (stdout)
{"errors": 123, "warnings": 456, "total": 579}

# Exit code
0 = success, non-zero = failure
```

**Why This Pattern**:
- Language-agnostic orchestration
- Easy to add new languages
- Testable in isolation
- No coupling between implementations

### 2. Benchmark Orchestration Pattern

**Location**: `scripts/benchmark.sh`

**Flow**:
```
For each language:
  1. Check if implementation exists
  2. Build if necessary (compiled languages)
  3. Run warmup iterations (JIT languages)
  4. Execute measured iterations (15x)
  5. Collect metrics per iteration
  6. Calculate statistics
  7. Write to results.json
```

**Key Decisions**:
- **Sequential execution**: Prevents hardware contention
- **Cooldown periods**: Reduces thermal throttling effects
- **Timeout protection**: 5-minute limit per run
- **Graceful degradation**: Missing toolchains don't break entire benchmark

**Metric Collection**:
Uses `/usr/bin/time -l` (BSD format on macOS) to capture:
- Real time (wall clock)
- User time (CPU in user space)
- System time (CPU in kernel)
- Maximum resident set size (peak memory)
- Calculated: CPU utilization percentage

### 3. Results Data Structure

**Format**: Hierarchical JSON

```json
{
  "metadata": {
    "timestamp": "2024-10-24T12:00:00Z",
    "log_size": "medium",
    "iterations": 15
  },
  "languages": {
    "python": {
      "times": [1.23, 1.21, 1.25, ...],
      "memory": [45.2, 45.8, 44.9, ...],
      "cpu": [180.5, 182.1, 179.8, ...],
      "stats": {
        "time_avg": 1.23,
        "memory_avg": 45.3,
        "cpu_avg": 180.8
      }
    }
  }
}
```

**Why This Structure**:
- Raw data preserved for alternative analysis
- Pre-computed stats for quick display
- Metadata tracks benchmark conditions
- Easy to extend with new metrics

### 4. Web Update Pipeline

**Pattern**: Automatic results embedding

**Components**:
1. `scripts/update_web.py`: Reads results.json, embeds in web/index.html
2. `scripts/publish_docs.py`: Syncs web/ → docs/ for GitHub Pages

**Data Flow**:
```
results.json → update_web.py → web/index.html → publish_docs.py → docs/ → GitHub Pages
```

**Why This Pattern**:
- No backend needed (static HTML)
- Results persist in HTML for offline viewing
- Automatic deployment via GitHub Actions
- Version control for results history

## Concurrency Implementation Patterns

### Python Implementation
```python
multiprocessing.Pool
- Worker processes = CPU count
- Chunk size = 10,000 lines
- Pattern matching via re.compile()
```

### Node.js Implementation
```javascript
worker_threads
- Workers = CPU count
- Message passing for results
- RegEx pattern matching
```

### C Implementation
```c
pthreads
- Threads = sysconf(_SC_NPROCESSORS_ONLN)
- Manual word boundary checking via strstr()
- Mutex for result aggregation
```

### Java/Kotlin Implementation
```java
ExecutorService with Fixed Thread Pool
- Threads = Runtime.availableProcessors()
- Stream API for parallel processing
- Pattern.compile() for regex
```

### Rust Implementation
```rust
rayon parallel iterators
- Automatic work stealing
- Par_lines() for parallel reading
- Regex crate for pattern matching
```

## Critical Implementation Paths

### Log Generation
**File**: `scripts/generate_logs.py`
```python
- Generates 3 sizes: small (10K), medium (100K), large (1M lines)
- Distribution: 70% INFO, 20% WARN, 10% ERROR
- Format: Apache/Nginx style logs
- Deterministic output (consistent across runs)
```

### Pattern Matching Requirements
All implementations must:
- Match whole words only (not substrings)
- Case-sensitive matching
- Count "ERROR" and "WARN" patterns
- Handle multiple occurrences per line

**Example Valid Matches**:
- "ERROR [Database] Connection failed" ✓
- "WARN [Cache] Memory threshold" ✓

**Example Invalid Matches**:
- "ERRORCODE" ✗ (not whole word)
- "WARNING" ✗ (different word)

### Build System Pattern

**Compiled Languages**: Each has `build.sh`
```bash
#!/bin/bash
# Language-specific compilation
# Must succeed or fail cleanly
# Output executable to predictable location
```

**Examples**:
- **C/C++**: `gcc -pthread -O3 solution.c -o solution`
- **Rust**: `cargo build --release && cp target/release/solution .`
- **Java**: `javac Solution.java`
- **C#**: `dotnet publish -c Release -o .`

## Data Storage Patterns

### Directory Structure
```
data/
├── synthetic/           # Generated test data
│   ├── small.log       # 10K lines
│   ├── medium.log      # 100K lines
│   └── large.log       # 1M lines
└── results.json        # Latest benchmark results
```

### Web Assets
```
web/                    # Development version
├── index.html         # Dashboard (results embedded)
├── app.js            # Chart.js visualizations
├── styles.css        # Styling
└── results.json      # Symlinked or copied

docs/                  # Production (GitHub Pages)
├── index.html        # Synced from web/
├── app.js
├── styles.css
└── results.json
```

## Key Technical Decisions

### 1. Why Bash for Orchestration?
- Universal on Unix systems
- Easy integration with `/usr/bin/time`
- Simple conditional logic for building
- No additional dependencies

### 2. Why 15 Iterations?
- Statistical significance (N > 10)
- Balances runtime vs accuracy
- Captures variance in measurements
- Reasonable for CI/CD pipelines

### 3. Why Warmup for JIT Languages?
- JIT compilation happens on first runs
- Optimization tiers require warmup
- Fair comparison: compare optimized performance
- Reflects real-world steady-state behavior

### 4. Why Sequential Not Parallel Testing?
- Eliminates resource contention
- Consistent thermal state
- Fair memory measurements
- Reproducible results

### 5. Why Static HTML Not Backend?
- Zero hosting costs (GitHub Pages)
- No server maintenance
- Offline accessibility
- Version control friendly
- Fast loading

## Component Relationships

### Language Implementation → Benchmark Script
- Loose coupling via file system
- Contract: run.sh interface
- No direct dependencies

### Benchmark Script → Results JSON
- One-way data flow
- Append-style updates
- Atomic file writes

### Results JSON → Web Dashboard
- Data embedding pattern
- No runtime dependency
- Offline capable

### Web → Docs → GitHub Pages
- Sync pattern
- Deployment pipeline
- Version controlled

## Error Handling Patterns

### Build Failures
- Captured in build.sh output
- Logged but don't stop benchmark
- Language skipped gracefully

### Runtime Failures
- Timeout protection (5 minutes)
- Exit code checking
- Partial results preserved

### Missing Dependencies
- Detected early (file existence checks)
- Clear error messages
- Graceful degradation

## Performance Optimization Patterns

### Across All Implementations
1. **Concurrent file reading**: Multiple threads/processes
2. **Compiled regex**: Pre-compile patterns
3. **Efficient aggregation**: Lock-free when possible
4. **Memory efficient**: Stream processing preferred
5. **Word boundary checking**: Not full regex when possible

### Language-Specific Optimizations
- **C**: Manual string operations, no regex overhead
- **Rust**: Zero-copy parsing, rayon work stealing
- **Python**: re.compile() for compiled patterns
- **Node.js**: V8 optimizations, worker thread pools
- **Java**: Parallel streams, compiled patterns
