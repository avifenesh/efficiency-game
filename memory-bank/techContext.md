# Technology Context

## Development Environment
- **Platform**: macOS (Sonoma or later)
- **Shell**: Zsh
- **Current Directory**: `/Users/avifen/efficiency-game`

## Language Requirements & Dependencies

### 1. Python (3.10+)
- **Interpreter**: System Python or pyenv
- **Libraries**: Standard library (threading, multiprocessing, re)
- **Concurrency**: Threading or multiprocessing modules
- **Installation**: Pre-installed on macOS

### 2. C (C11)
- **Compiler**: Clang (via Xcode Command Line Tools)
- **Libraries**: pthreads, stdio, stdlib, string
- **Build**: `clang -pthread -O3`
- **Installation**: `xcode-select --install`

### 3. C++ (C++17)
- **Compiler**: Clang++ or g++
- **Libraries**: std::thread, std::regex, std::fstream
- **Build**: `clang++ -std=c++17 -pthread -O3`
- **Installation**: Via Xcode Command Line Tools

### 4. C# (.NET 7+)
- **Runtime**: .NET SDK
- **Libraries**: System.Threading.Tasks, System.IO
- **Build**: `dotnet build -c Release`
- **Installation**: `brew install dotnet`

### 5. Node.js (v18+)
- **Runtime**: Node.js with V8 engine
- **Libraries**: worker_threads, fs/promises
- **Execution**: `node solution.js`
- **Installation**: `brew install node`

### 6. Rust (1.70+)
- **Compiler**: rustc via cargo
- **Libraries**: rayon (data parallelism), tokio (async), regex
- **Build**: `cargo build --release`
- **Installation**: `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh`

### 7. Zig (0.11+)
- **Compiler**: zig
- **Libraries**: std.Thread, std.fs
- **Build**: `zig build-exe -O ReleaseFast`
- **Installation**: `brew install zig`

### 8. Nim (2.0+)
- **Compiler**: nim
- **Libraries**: std/threadpool, std/re
- **Build**: `nim c -d:release --threads:on`
- **Installation**: `brew install nim`

### 9. Mojo (Latest)
- **Runtime**: Mojo SDK
- **Libraries**: Mojo standard library
- **Build**: `mojo build`
- **Installation**: Follow Modular installation guide
- **Note**: May not be available, implement if possible

### 10. Java (JDK 17+)
- **Runtime**: OpenJDK or Oracle JDK
- **Libraries**: java.util.concurrent, java.nio.file
- **Build**: `javac Solution.java`
- **Run**: `java Solution`
- **Installation**: `brew install openjdk`

### 11. Kotlin (1.9+)
- **Compiler**: kotlinc
- **Libraries**: kotlinx.coroutines
- **Build**: `kotlinc solution.kt -include-runtime -d solution.jar`
- **Run**: `java -jar solution.jar`
- **Installation**: `brew install kotlin`

### 12. Ruby (3.2+)
- **Interpreter**: Ruby MRI
- **Libraries**: Thread, Ractor, Regexp
- **Execution**: `ruby solution.rb`
- **Installation**: Pre-installed or `brew install ruby`

### 13. PHP (8.2+)
- **Interpreter**: PHP CLI
- **Libraries**: parallel extension or pcntl
- **Execution**: `php solution.php`
- **Installation**: `brew install php`

### 14. Scala (3.x)
- **Compiler**: scalac
- **Runtime**: JVM
- **Libraries**: scala.concurrent, scala.collection.parallel
- **Build**: `scalac solution.scala`
- **Installation**: `brew install scala`

### 15. Elixir (1.15+)
- **Runtime**: Erlang VM (BEAM)
- **Libraries**: Task, Flow, Stream
- **Execution**: `elixir solution.exs`
- **Installation**: `brew install elixir`

### 16. Perl (5.36+)
- **Interpreter**: Perl
- **Libraries**: threads, Thread::Queue
- **Execution**: `perl solution.pl`
- **Installation**: Pre-installed on macOS

## Build Tools & Scripts

### Benchmark Orchestrator
- **Language**: Bash
- **Dependencies**: 
  - `/usr/bin/time` (BSD version with -l flag)
  - `jq` for JSON processing
  - Standard Unix tools (awk, sed, grep)

### Log Generator
- **Language**: Python 3
- **Libraries**: random, datetime, sys
- **Purpose**: Generate reproducible synthetic logs

### Measurement Wrapper
- **Tool**: `/usr/bin/time -l`
- **Output Format**: Text-based metrics
- **Parsing**: Bash/Python script to extract metrics

## Web UI Technology Stack

### Core Technologies
- **HTML5**: Semantic structure
- **CSS3**: Grid, Flexbox, animations, transitions
- **JavaScript (ES6+)**: Vanilla JS, no frameworks

### Visualization Libraries
- **Chart.js** (v4.x): For bar charts and comparisons
  - CDN: `https://cdn.jsdelivr.net/npm/chart.js`
  - Animations and responsive charts
  
OR

- **D3.js** (v7.x): For custom visualizations
  - CDN: `https://d3js.org/d3.v7.min.js`
  - More control over custom animations

### Design System
- **Colors**: 
  - Background: Dark theme (#1a1a2e, #16213e)
  - Accents: Gradient (#00d4ff → #7b2cbf)
  - Text: #ffffff, #e0e0e0
  - Success: #00ff88
  - Warning: #ffaa00
  - Error: #ff3366

- **Typography**:
  - Headers: 'Inter', 'SF Pro Display', sans-serif
  - Body: 'Inter', 'SF Pro Text', sans-serif
  - Code: 'Fira Code', 'Monaco', monospace

- **Spacing**: 8px base unit system

### Browser Support
- Modern browsers only (Chrome 90+, Safari 15+, Firefox 88+)
- No IE11 support
- Uses modern JS features (fetch, async/await, ES modules)

## Development Workflow

### Phase 1: Setup
```bash
# Install required languages (one-time)
brew install node rust python go zig nim openjdk kotlin scala elixir ruby php

# Verify installations
./scripts/verify_env.sh
```

### Phase 2: Generate Logs
```bash
python3 scripts/generate_logs.py
# Creates data/synthetic/{small,medium,large}.log
```

### Phase 3: Build Implementations
```bash
# Automated by benchmark.sh
# Compiles all compiled languages
./scripts/build_all.sh
```

### Phase 4: Run Benchmarks
```bash
./scripts/benchmark.sh
# Outputs to data/results.json
```

### Phase 5: View Results
```bash
open web/index.html
# Or serve with local server
python3 -m http.server 8000 --directory web
```

## Performance Measurement Tools

### macOS `/usr/bin/time -l`
Provides:
- Real time (wall clock)
- User time (CPU user space)
- System time (CPU kernel space)
- Maximum resident set size (bytes)
- Page faults
- Context switches
- CPU utilization percentage

### Output Parsing
```bash
/usr/bin/time -l ./program 2>&1 | grep "maximum resident set size"
```

Extract metrics:
- `real`: Wall clock time
- `user`: CPU time in user mode
- `sys`: CPU time in kernel mode
- `maximum resident set size`: Peak memory in bytes

## Technical Constraints

### Memory
- No artificial limits
- System RAM available to all implementations
- Monitor for excessive usage (>2GB flagged)

### CPU
- Use all available cores
- No CPU affinity restrictions
- Fair scheduling by OS

### Timeout
- 5 minutes max per iteration
- Prevents hanging implementations
- Kill signal (SIGTERM then SIGKILL)

### File I/O
- All logs in `data/synthetic/`
- Read-only access
- No caching between runs (clear OS cache if possible)

## Error Handling Strategy

### Build Failures
- Log to `build_errors.log`
- Mark language as "Not Available"
- Continue with other languages

### Runtime Failures
- Capture exit code
- Log stderr
- Mark iteration as failed
- Continue with remaining languages

### Measurement Failures
- Use partial data if available
- Flag incomplete results
- Include warning in UI

## Version Control
- **Git**: Track all source files
- **Ignore**: Build artifacts, binaries, large log files
- **Include**: Small sample logs for testing

## Dependencies Installation Script
Create `scripts/install_deps.sh` to automate:
```bash
#!/bin/bash
# Install all required language runtimes
brew install node python rust go zig nim openjdk kotlin scala elixir ruby php dotnet
```

## Notes
- Some languages (Mojo) may not be available on macOS yet
- Fall back to manual installation for unavailable packages
- Document any manual steps in language-specific README files
