# ⚡ Language Efficiency Race

A comprehensive benchmark comparing the execution efficiency of multiple programming languages through a real-world concurrent log anomaly detection task.

## 🎯 Overview

This project measures and compares the performance (execution time, memory usage, CPU utilization) of different programming languages when processing log files to detect and count anomalies (ERROR and WARN patterns).

### Current Languages Tested (13)
Benchmarks are captured for: C, C++, C#, Elixir, Java, Julia, Kotlin, Nim, Node.js, PHP, Python, Ruby, and Rust. The latest metrics live on the dashboard linked below.

## 📊 Dashboard

View the interactive benchmark dashboard:
```bash
open web/index.html
```

Or visit the published GitHub Pages site (docs synced from `web/`):

```
https://avifenesh.github.io/efficiency-game/
```

Benchmark numbers are intentionally kept out of the README—use the dashboard for the latest performance snapshots.

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
│   ├── c/
│   ├── cpp/
│   ├── csharp/
│   ├── elixir/
│   ├── java/
│   ├── julia/
│   ├── kotlin/
│   ├── nim/
│   ├── nodejs/
│   ├── php/
│   ├── python/
│   ├── ruby/
│   └── rust/
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

## 🔧 Requirements

Benchmarking every language target requires the corresponding toolchains. At minimum:

- macOS with Xcode Command Line Tools (`xcode-select --install`) for GCC/Clang
- Python 3.10+
- Node.js 18+
- `/usr/bin/time` with BSD `-l` support (default on macOS)

To build or execute specific implementations you will also need their runtimes/compilers (e.g., Nim, .NET SDK, Java, Julia, PHP, Elixir, Rust). Install only what you plan to benchmark; languages without an available toolchain will be skipped by `benchmark.sh`.

## 📄 License

This is a benchmark project for educational and comparison purposes.

## 🙏 Acknowledgments

Built to answer the age-old question: "Which language is fastest for real-world tasks?"

---

**Note**: This benchmark focuses on a specific workload (concurrent log processing). Results may vary for different types of tasks. Choose languages based on your specific needs, team expertise, and ecosystem requirements.
