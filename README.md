# ⚡ Language Efficiency Race

A comprehensive benchmark comparing the execution efficiency of multiple programming languages through a real-world concurrent log anomaly detection task.

## 🎯 Overview

This project measures and compares the performance (execution time, memory usage, CPU utilization) of different programming languages when processing log files to detect and count anomalies (ERROR and WARN patterns).

### Current Languages Tested (13)
Benchmarks below reflect the medium dataset (100K log lines, 5 iterations).

- ✅ **C** – 0.024s (fastest)
- ✅ **Node.js** – 0.054s
- ✅ **C#** – 0.076s
- ✅ **Rust** – 0.090s
- ✅ **Java** – 0.098s
- ✅ **C++** – 0.104s
- ✅ **Nim** – 0.134s
- ✅ **Kotlin** – 0.150s
- ✅ **PHP** – 0.180s
- ✅ **Ruby** – 0.192s
- ✅ **Python** – 0.228s
- ✅ **Elixir** – 0.414s
- ✅ **Julia** – 0.534s

## 📊 Results

View the beautiful interactive visualization:
```bash
open web/index.html
```

### Current Benchmark Results (Medium Dataset - 100K lines)
| Rank | Language | Avg Time | Avg Memory | Speed Multiplier* |
|------|----------|----------|------------|-------------------|
| 🥇 | C | 0.024s | 8.37 MB | 1.0x |
| 🥈 | Node.js | 0.054s | 64.95 MB | 2.3x |
| 🥉 | C# | 0.076s | 46.32 MB | 3.2x |
| 4 | Rust | 0.090s | 10.48 MB | 3.8x |
| 5 | Java | 0.098s | 51.13 MB | 4.1x |
| 6 | C++ | 0.104s | 12.95 MB | 4.3x |
| 7 | Nim | 0.134s | 27.98 MB | 5.6x |
| 8 | Kotlin | 0.150s | 58.73 MB | 6.3x |
| 9 | PHP | 0.180s | 35.64 MB | 7.5x |
| 10 | Ruby | 0.192s | 41.09 MB | 8.0x |
| 11 | Python | 0.228s | 40.61 MB | 9.5x |
| 12 | Elixir | 0.414s | 95.16 MB | 17.3x |
| 13 | Julia | 0.534s | 273.36 MB | 22.3x |

\*Multiplier relative to the fastest average runtime (C).

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
├── LICENSE
├── README.md
├── data/
│   ├── synthetic/           # Generated log files
│   │   ├── small.log
│   │   ├── medium.log
│   │   └── large.log
│   └── results.json         # Benchmark results
├── docs/                    # Static bundle for GitHub Pages
│   ├── index.html
│   └── ...
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
│   ├── benchmark.sh         # Benchmark orchestrator
│   ├── generate_logs.py     # Log generator
│   ├── publish_docs.py      # Sync web → docs
│   └── update_web.py        # Embed latest results in dashboard
├── life/                    # Pixi environment for experimental work
│   └── pixi.toml
└── web/
   ├── app.js
   ├── index.html
   ├── results.json
   └── styles.css
```

## 🔬 Methodology

### Task Specification
Each implementation must:
1. Read log files using concurrent/parallel processing
2. Scan for ERROR and WARN patterns
3. Count total occurrences
4. Output JSON: `{"errors": N, "warnings": N, "total": N}`

### Benchmarking Process
1. **Warmup**: 1 iteration (for JIT-focused runtimes)
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
- Warmup for JIT languages (Java, C#, Kotlin, Node.js)
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
1. **Native Systems** (C, Rust, C++): Sub-0.11s with low memory usage
2. **Managed Runtimes** (C#, Java, Kotlin, Node.js): 0.05–0.15s after warmup
3. **Compiled Scripting** (Nim, PHP): 0.13–0.18s with moderate memory
4. **Dynamic Scripting** (Ruby, Python): 0.19–0.23s, higher CPU per work unit
5. **Concurrency Platforms** (Elixir, Julia): Favor throughput but trade raw speed

### Observations
- **C is blazing fast**: 10x faster than Python
- **Memory efficiency**: C uses ~8x less memory than Node.js
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
