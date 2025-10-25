# Technical Context: Language Efficiency Race

## Technology Stack

### Core Technologies

#### Programming Languages (Implementations)
1. **C** - gcc/clang, pthreads
2. **C++** - g++, STL threading
3. **C#** - .NET SDK 6.0+, System.Threading
4. **Elixir** - 1.14+, Task module
5. **Java** - JDK 11+, ExecutorService
6. **Julia** - 1.8+, @threads macro
7. **Kotlin** - 1.8+, coroutines
8. **Nim** - 1.6+, threadpool
9. **Node.js** - 18+, worker_threads
10. **PHP** - 8.0+, parallel extension
11. **Python** - 3.10+, multiprocessing
12. **Ruby** - 3.0+, Ractor/Thread
13. **Rust** - 1.70+, rayon

#### Orchestration & Tooling
- **Bash**: Benchmark orchestration (benchmark.sh)
- **Python 3.10+**: Log generation, web updates, docs publishing
- **BSD time**: Performance metrics collection (`/usr/bin/time -l`)

#### Frontend Technologies
- **HTML5**: Dashboard structure
- **CSS3**: Styling with gradients, animations
- **JavaScript (Vanilla)**: Chart rendering, data visualization
- **Chart.js 3.x**: Interactive performance charts

#### Infrastructure
- **Git**: Version control
- **GitHub Pages**: Static site hosting (docs/)
- **GitHub Actions**: CI/CD for docs deployment

## Development Environment

### Required Tools (Minimum)
```bash
# Core requirements
- macOS with Xcode Command Line Tools
- Python 3.10+
- /usr/bin/time with BSD -l flag support

# For full benchmark suite
- All 13 language toolchains (see below)
```

### Platform Specifics
- **Primary Platform**: macOS (Apple Silicon or Intel)
- **Shell**: Bash 3.2+ (macOS default)
- **Time Command**: BSD version with `-l` flag (memory tracking)

### Language Toolchain Requirements

#### Compiled Languages
```bash
# C/C++
gcc or clang (via Xcode Command Line Tools)

# Rust
rustc 1.70+, cargo

# Nim
nim 1.6+, nimble

# C#
.NET SDK 6.0+ (dotnet CLI)

# Java/Kotlin
JDK 11+ (javac, java)
```

#### Interpreted Languages
```bash
# Python
python3 (system or Homebrew)

# Node.js
node 18+ (nvm recommended)

# Ruby
ruby 3.0+ (rbenv recommended)

# PHP
php 8.0+ (Homebrew)

# Julia
julia 1.8+ (juliaup recommended)

# Elixir
elixir 1.14+ (asdf recommended)
```

### Installation Commands (macOS)
```bash
# Xcode Command Line Tools
xcode-select --install

# Homebrew (if needed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Language toolchains via Homebrew
brew install python node rust nim dotnet openjdk php julia elixir
```

## Project Setup

### Initial Setup
```bash
# Clone repository
git clone https://github.com/avifenesh/efficiency-game.git
cd efficiency-game

# Generate test data
python3 scripts/generate_logs.py

# Run benchmark
chmod +x scripts/benchmark.sh
./scripts/benchmark.sh

# View results
open web/index.html
```

### Directory Permissions
```bash
# Make scripts executable
chmod +x scripts/*.sh
chmod +x implementations/*/run.sh
chmod +x implementations/*/build.sh
```

## Technical Constraints

### Platform Limitations
1. **macOS Only**: `/usr/bin/time -l` is BSD-specific
2. **Sequential Execution**: Hardware contention would affect results
3. **Timeout**: 5-minute limit per run prevents infinite loops
4. **Memory Measurement**: Peak RSS only (not average/instantaneous)

### Performance Constraints
1. **File I/O**: All implementations read same files from disk
2. **Pattern Matching**: Must use word boundaries (affects regex complexity)
3. **Concurrency**: Must use multiple threads/processes (no single-threaded)
4. **Output Format**: Strict JSON format required

### Resource Constraints
1. **CPU**: Uses all available cores (no artificial limits)
2. **Memory**: No artificial limits (native language behavior)
3. **Disk**: Read-only access to log files
4. **Network**: No network access needed

## Dependencies

### Runtime Dependencies

#### Python Scripts
```python
# scripts/generate_logs.py
- Standard library only (no external packages)
- Uses: random, datetime, os, sys

# scripts/update_web.py
- Standard library only
- Uses: json, re, sys

# scripts/publish_docs.py
- Standard library only
- Uses: shutil, os, sys
```

#### Bash Scripts
```bash
# scripts/benchmark.sh
- bash 3.2+
- /usr/bin/time (BSD version)
- Standard Unix tools: grep, awk, bc, seq
```

### Build Dependencies

Each language implementation may require:
- Language-specific compiler/runtime
- Standard library (usually included)
- Threading/concurrency libraries (usually built-in)

**No external packages** required for any implementation - all use standard libraries only.

## Tool Usage Patterns

### Benchmark Execution
```bash
# Full benchmark (all languages)
./scripts/benchmark.sh

# Single language (manual)
cd implementations/python
./run.sh ../../data/synthetic/medium.log

# Generate fresh logs
python3 scripts/generate_logs.py

# Update web dashboard manually
python3 scripts/update_web.py

# Sync to docs/ for GitHub Pages
python3 scripts/publish_docs.py
```

### Performance Measurement
```bash
# Manual timing (macOS)
/usr/bin/time -l ./implementations/python/run.sh data/synthetic/medium.log

# Output includes:
# - real, user, sys time
# - maximum resident set size
# - page faults, swaps, etc.
```

### Result Analysis
```bash
# View raw results
cat data/results.json | python3 -m json.tool

# Extract specific language
cat data/results.json | python3 -c "import json,sys; print(json.load(sys.stdin)['languages']['python'])"
```

## Configuration Files

### Git Configuration
```gitignore
# .gitignore
data/synthetic/*.log  # Generated test data
data/results.json     # Benchmark results
implementations/*/solution  # Compiled binaries
implementations/*/target/   # Build artifacts
implementations/*/bin/      # Build artifacts
implementations/*/obj/      # Build artifacts
```

### GitHub Actions
```yaml
# .github/workflows/deploy-pages.yml
- Triggers on push to main
- Runs publish_docs.py
- Deploys docs/ to GitHub Pages
```

### Pixi Environment (Optional)
```toml
# life/pixi.toml
- Experimental environment for future enhancements
- Not required for core functionality
```

## Technical Debt & Known Issues

### Current Limitations
1. **Platform Dependence**: Only works on macOS (BSD time command)
2. **Manual Updates**: web/results.json must be manually synced
3. **No CI Benchmarks**: GitHub Actions doesn't run actual benchmarks
4. **Memory Metrics**: Peak RSS only, not detailed memory profiling

### Future Improvements
1. Linux support (GNU time has different flags)
2. Windows support (requires different timing mechanism)
3. Docker containers for reproducible environments
4. Automated PR benchmarks
5. Historical trend tracking

## Build System Details

### Compilation Flags

#### C/C++
```bash
gcc -pthread -O3 -o solution solution.c
# -pthread: Enable POSIX threads
# -O3: Maximum optimization
# -o: Output executable name
```

#### Rust
```bash
cargo build --release
# --release: Optimized build with LTO
# Output: target/release/<project_name>
```

#### C#
```bash
dotnet publish -c Release -o .
# -c Release: Release configuration
# -o: Output directory
```

#### Java
```bash
javac Solution.java
# Standard compilation
# Runs via: java Solution
```

#### Nim
```bash
nim c -d:release --threads:on -o:solution solution.nim
# -d:release: Release mode
# --threads:on: Enable threading
# -o: Output name
```

## Performance Monitoring

### Metrics Collected
```bash
# Time metrics (seconds)
- real: Wall clock time
- user: CPU time in user mode
- sys: CPU time in kernel mode

# Memory metrics (bytes)
- maximum resident set size: Peak memory usage

# Calculated metrics
- CPU %: ((user + sys) / real) * 100
- Memory MB: max_rss / 1024 / 1024
```

### Statistical Analysis
```bash
# For each metric, calculated:
- Average (mean)
- All raw values preserved for:
  - Min/max
  - Median
  - Standard deviation (external analysis)
```

## Data Flow

### Pipeline Overview
```
1. generate_logs.py creates synthetic logs
   ↓
2. benchmark.sh orchestrates execution
   ↓
3. Each implementation processes logs
   ↓
4. /usr/bin/time captures metrics
   ↓
5. benchmark.sh aggregates to results.json
   ↓
6. update_web.py embeds results in HTML
   ↓
7. publish_docs.py syncs to docs/
   ↓
8. GitHub Actions deploys to Pages
```

## Version Control Strategy

### Branching
- **main**: Production branch (auto-deploys to GitHub Pages)
- Feature branches for new language implementations
- No strict branch protection (single developer project)

### Commit Patterns
- Implementation additions: "Add <language> implementation"
- Documentation: "Update README/docs"
- Benchmark updates: "Update benchmark results"

## Security Considerations

### Safe Practices
- No external dependencies (reduces supply chain risk)
- Read-only log file access
- No network operations in implementations
- Timeout protection prevents resource exhaustion

### Potential Risks
- Arbitrary code execution (implementations run user code)
- Resource exhaustion (mitigated by timeout)
- Disk space (large log files)

## Testing Strategy

### Validation
1. **Output Format**: All implementations must output valid JSON
2. **Correctness**: All implementations must return same counts
3. **Performance**: Runs must complete within timeout
4. **Reproducibility**: Multiple runs should have low variance

### No Formal Test Suite
- Manual validation via benchmark execution
- Correctness checked by comparing counts across languages
- Performance is the test metric itself
