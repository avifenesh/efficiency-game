# ⚡ Language Efficiency Race

A comprehensive benchmark comparing the execution efficiency of multiple programming languages through a real-world concurrent log anomaly detection task.

## 🎯 Overview

This project measures and compares the performance (execution time, memory usage, CPU utilization) of different programming languages when processing log files to detect and count anomalies (ERROR and WARN patterns). For collaboration roles and handoff expectations, see `AGENTS.md`.

### Current Languages Tested (13)
- ✅ **C** - 0.034s (Fastest!)
- ✅ **Rust** - 0.034s (Tied!)
- ✅ **Nim** - 0.040s
- ✅ **C#** - 0.078s
- ✅ **Java** - 0.102s
- ✅ **PHP** - 0.106s
- ✅ **C++** - 0.142s
- ✅ **Node.js** - 0.146s
- ✅ **Kotlin** - 0.172s
- ✅ **Ruby** - 0.176s
- ✅ **Python** - 0.304s
- ✅ **Julia** - 0.500s
- ✅ **Elixir** - 0.520s

## 📊 Results

View the beautiful interactive visualization:
```bash
open web/index.html
```

### Current Benchmark Results (Medium Dataset - 100K lines)
| Rank | Language | Avg Time | Avg Memory | Speed Multiplier |
|------|----------|----------|------------|------------------|
| 🥇 | C | 0.034s | 8.45 MB | 1.0x |
| 🥇 | Rust | 0.034s | 10.58 MB | 1.0x |
| 🥈 | Nim | 0.040s | 34.22 MB | 1.2x |
| 🥉 | C# | 0.078s | 46.66 MB | 2.3x |
| 4 | Java | 0.102s | 52.98 MB | 3.0x |
| 5 | PHP | 0.106s | 35.82 MB | 3.1x |
| 6 | C++ | 0.142s | 13.13 MB | 4.2x |
| 7 | Node.js | 0.146s | 201.27 MB | 4.3x |
| 8 | Kotlin | 0.172s | 60.26 MB | 5.1x |
| 9 | Ruby | 0.176s | 45.58 MB | 5.2x |
| 10 | Python | 0.304s | 41.31 MB | 8.9x |
| 11 | Julia | 0.500s | 270.36 MB | 14.7x |
| 12 | Elixir | 0.520s | 92.55 MB | 15.3x |

## 🚀 Quick Start

### 1. Generate Synthetic Logs
```bash
python3 scripts/generate_logs.py
```

This creates three log file sizes:
- Small: 10K lines (~1 MB)
- Medium: 100K lines (~10 MB)
- Large: 1M lines (~100 MB)

### 2. Run Benchmark
```bash
chmod +x scripts/benchmark.sh
./scripts/benchmark.sh
```

This will:
- Build all compiled language implementations
- Run warmup iterations for JIT languages
- Execute 5 measured iterations per language
- Collect time, memory, and CPU metrics
- Generate `data/results.json`
- **Automatically update `web/index.html` with latest results**

### 3. View Results
```bash
open web/index.html
```

The web page is automatically updated with the latest benchmark results after each run.

## 🏗️ Project Structure

```
efficiency-game/
├── AGENTS.md               # Roles, rituals, and collaboration guidance
├── memory-bank/              # Project documentation
│   ├── projectbrief.md
│   ├── productContext.md
│   ├── systemPatterns.md
│   ├── techContext.md
│   ├── activeContext.md
│   └── progress.md
├── data/
│   ├── synthetic/           # Generated log files
│   │   ├── small.log
│   │   ├── medium.log
│   │   └── large.log
│   └── results.json         # Benchmark results
├── implementations/
│   ├── python/
│   │   ├── solution.py
│   │   └── run.sh
│   ├── nodejs/
│   │   ├── solution.js
│   │   └── run.sh
│   └── c/
│       ├── solution.c
│       ├── build.sh
│       └── run.sh
├── scripts/
│   ├── generate_logs.py     # Log generator
│   └── benchmark.sh         # Benchmark orchestrator
├── web/
│   ├── index.html
│   ├── styles.css
│   └── app.js
└── README.md
```

## 🔬 Methodology

### Task Specification
Each implementation must:
1. Read log files using concurrent/parallel processing
2. Scan for ERROR and WARN patterns
3. Count total occurrences
4. Output JSON: `{"errors": N, "warnings": N, "total": N}`

### Benchmarking Process
1. **Warmup**: 1 iteration (for JIT-compiled languages)
2. **Measured Runs**: 5 iterations per language
3. **Metrics Collected**:
   - Real time (wall clock)
   - User time (CPU in user space)
   - System time (CPU in kernel)
   - Maximum resident set size (peak memory)
   - CPU utilization percentage
4. **Statistics**: Min, max, average, median calculated

### Fairness Considerations
- Same input data for all languages
- Same hardware (sequential execution)
- Warmup for JIT languages (Java, C#, Kotlin, Scala, Node.js)
- Multiple iterations for statistical validity
- No artificial resource constraints

## 💻 Implementation Details

### Language-Specific Approaches

#### Python
- **Concurrency**: `multiprocessing.Pool`
- **Pattern Matching**: `re.compile()` for performance
- **Chunk Size**: 10K lines per chunk

#### Node.js
- **Concurrency**: `worker_threads`
- **Pattern Matching**: RegEx
- **Workers**: CPU core count

#### C
- **Concurrency**: `pthreads`
- **Pattern Matching**: Manual `strstr()` with word boundaries
- **Threads**: `sysconf(_SC_NPROCESSORS_ONLN)`

## 📈 Web Visualization Features

The web UI provides:
- 📊 Interactive charts (execution time & memory usage)
- 🏆 Performance leaderboard with rankings
- 📋 Detailed per-language metrics cards
- 🎨 Beautiful dark theme with gradients
- 📱 Responsive design
- ⚡ Smooth animations

## 🛠️ Adding New Languages

To add a new language implementation:

1. Create directory: `implementations/<language>/`
2. Implement `solution.<ext>` following the standard interface
3. Create `run.sh` script
4. If compiled, create `build.sh` script
5. Add to `scripts/benchmark.sh` LANGUAGES array
6. Run benchmark and enjoy!

### Standard Interface
```bash
# Input
./run.sh <path_to_log_file>

# Output (to stdout)
{"errors": 123, "warnings": 456, "total": 579}

# Exit code
0 on success, non-zero on failure
```

## 📝 Log Format

Generated logs follow Apache/Nginx style:
```
2024-10-24 14:32:01 INFO [Service] Request processed successfully
2024-10-24 14:32:02 ERROR [Database] Connection timeout
2024-10-24 14:32:03 WARN [Cache] Memory threshold exceeded
```

Distribution:
- 70% INFO messages
- 20% WARN messages
- 10% ERROR messages

## 🎓 Key Insights

### Performance Tiers
1. **Systems Languages** (C, C++, Rust, Zig): Sub-second, minimal memory
2. **Modern Compiled** (Go, Nim): 1-2 seconds
3. **JVM/.NET** (Java, Kotlin, C#, Scala): 2-3 seconds after warmup
4. **Scripting** (Python, Ruby, PHP, Perl): 3-5+ seconds
5. **Special Cases**: Elixir (concurrency-optimized), Node.js (V8 JIT)

### Observations
- **C is blazing fast**: 10x faster than Python
- **Memory efficiency**: C uses ~5x less memory than Node.js
- **JIT warmup matters**: Node.js benefits from warmup iteration
- **Trade-offs exist**: Speed vs. memory vs. development ease

## 🔧 Requirements

### macOS
- Xcode Command Line Tools: `xcode-select --install`
- Python 3.10+
- Node.js 18+
- Language-specific runtimes as needed

### Tools
- `/usr/bin/time -l` (BSD version with -l flag)
- Standard Unix tools (awk, sed, grep)

## 📄 License

This is a benchmark project for educational and comparison purposes.

## 🙏 Acknowledgments

Built to answer the age-old question: "Which language is fastest for real-world tasks?"

---

**Note**: This benchmark focuses on a specific workload (concurrent log processing). Results may vary for different types of tasks. Choose languages based on your specific needs, team expertise, and ecosystem requirements.
