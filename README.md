# ⚡ Language Efficiency Race

A comprehensive benchmark comparing the execution efficiency of multiple programming languages through a real-world concurrent log anomaly detection task.

## 📊 Live Benchmark Results

**[View Interactive Dashboard →](https://avifenesh.github.io/efficiency-game/)**

Explore real-time performance metrics, charts, and rankings for all languages.

## 🎯 Overview

This project measures and compares the performance (execution time, memory usage, CPU utilization) of different programming languages when processing log files to detect and count anomalies (ERROR and WARN patterns).

### Current Languages Tested (27)

Assembly, Bash, C, C3, Carbon, C++, C#, Elixir, Erlang, Fortran, F#, Gleam, Go, Java, Julia, Kotlin, Lisp (SBCL), Lua, Nim, Node.js, OCaml, Perl, PHP, Python, Ruby, Rust, and Zig.

All benchmark results are available on the interactive dashboard. The latest metrics and visualizations are updated after each benchmark run.

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

> 💡 Tip: Before the first run, execute `./scripts/check_dependencies.sh` to make sure every language toolchain is available. Pass `--install` to let it invoke Homebrew for supported packages automatically.

This will:
- Build all compiled language implementations
- Run warmup iterations for JIT languages
- Execute 10 measured iterations per language
- Run a warmup pass before timing and a cooldown pause between iterations
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
│   ├── assembly/
│   ├── bash/
│   ├── c/
│   ├── c3/
│   ├── carbon/
│   ├── cpp/
│   ├── csharp/
│   ├── elixir/
│   ├── erlang/
│   ├── fortran/
│   ├── fsharp/
│   ├── gleam/
│   ├── go/
│   ├── java/
│   ├── julia/
│   ├── kotlin/
│   ├── lisp/
│   ├── lua/
│   ├── nim/
│   ├── nodejs/
│   ├── ocaml/
│   ├── perl/
│   ├── php/
│   ├── python/
│   ├── ruby/
│   ├── rust/
│   └── zig/
├── scripts/
│   ├── benchmark.sh         # Benchmark orchestrator
│   ├── check_dependencies.sh # Toolchain helper (new)
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
1. **Warmup**: 1 unmeasured run prior to timing (optional for languages that benefit)
2. **Measured Runs**: 10 iterations per language with cooldown pauses
3. **Cooldown**: 2-second pause between iterations to stabilise resource usage
4. **Metrics Collected**:
   - Real time (wall clock)
   - User time (CPU in user space)
   - System time (CPU in kernel)
   - Maximum resident set size (peak memory)
   - CPU utilization percentage
5. **Statistics**: Min, max, average, median calculated

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

Because every implementation is native to its ecosystem, you’ll need the corresponding compilers/runtimes. A helper script ships with the repo:

```bash
./scripts/check_dependencies.sh         # List missing toolchains
./scripts/check_dependencies.sh --install  # Attempt Homebrew installs when possible
```

> ℹ️ The script checks for the same commands that `benchmark.sh` uses. Run it anytime your environment changes.

### Toolchain checklist (macOS + Homebrew)

| Languages / Purpose | Command(s) checked | Installation hint |
| --- | --- | --- |
| Benchmark harness & Python impl | `python3`, `bc`, `timeout` | `brew install python@3.11 bc coreutils`<br/>and symlink `gtimeout` → `timeout` (`sudo ln -sf /opt/homebrew/bin/gtimeout /usr/local/bin/timeout`) |
| C, C++, Carbon, Assembly builds | `clang`, `clang++` | Install Apple Command Line Tools: `xcode-select --install` |
| Bash implementation | `bash` (bundled) | preinstalled on macOS |
| Fortran implementation | `gfortran` | `brew install gcc` |
| C3 implementation | `c3c` | `brew install c3c` |
| C#, F# implementations | `dotnet` | `brew install dotnet-sdk` |
| Java implementation | `javac`, `java` | `brew install openjdk` |
| Kotlin implementation | `kotlinc` | `brew install kotlin` (pulls in OpenJDK) |
| Go implementation | `go` | `brew install go` |
| Rust implementation | `cargo` | `brew install rust` |
| Zig implementation | `zig` | `brew install zig` |
| Julia implementation | `julia` | `brew install julia` |
| Nim implementation | `nim` | `brew install nim` |
| Lua implementation | `lua` | `brew install lua` |
| Node.js implementation | `node` | `brew install node` |
| Ruby implementation | `ruby` | `brew install ruby` |
| PHP implementation | `php` | `brew install php` |
| Elixir implementation | `elixir` | `brew install elixir` (installs Erlang + `escript`) |
| Erlang implementation | `escript` | `brew install erlang` (if not already pulled in via Elixir) |
| Gleam implementation | `gleam` | `brew install gleam` |
| Common Lisp implementation | `sbcl` | `brew install sbcl` |
| OCaml implementation | `ocamlopt`, optional `ocamlfind`, `domainslib` | `brew install ocaml`; add `opam install ocamlfind domainslib` for parallel build |
| Perl implementation | Core modules (`threads`, `JSON::PP`) | Bundled with system Perl |

Additional notes:

- The dependency checker only reports what’s missing. Languages without a toolchain are skipped by `benchmark.sh`, so you can opt out of installs.
- Installing Apple Command Line Tools (`xcode-select --install`) is interactive and must be done manually.
- For OCaml, initializing opam (`brew install opam && opam init`) is recommended before installing optional packages.
- Ensure Homebrew itself is available (`/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`).

## 📄 License

This is a benchmark project for educational and comparison purposes.

## 🙏 Acknowledgments

Built to answer the age-old question: "Which language is fastest for real-world tasks?"

---

**Note**: This benchmark focuses on a specific workload (concurrent log processing). Results may vary for different types of tasks. Choose languages based on your specific needs, team expertise, and ecosystem requirements.
