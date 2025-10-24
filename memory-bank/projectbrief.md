# Language Efficiency Race - Project Brief

## Project Overview
Create a comprehensive benchmark comparing the execution efficiency of 16 programming languages through a real-world concurrent log anomaly detection task. Results will be visualized through a beautiful web-based UI.

## Core Objective
Measure and compare the performance (time, memory, CPU usage) of different programming languages when processing log files to detect and count anomalies (ERROR and WARN patterns).

## Languages to Benchmark
1. Python
2. C
3. C++
4. C#
5. Node.js
6. Rust
7. Zig
8. Nim
9. Mojo
10. Java
11. Kotlin
12. Ruby
13. PHP
14. Scala
15. Elixir
16. Perl

## Task Specification
**Concurrent Log Anomaly Counter**: Each implementation must:
- Read log files using concurrent/parallel processing
- Scan for ERROR and WARN patterns
- Count total occurrences
- Process efficiently using language-specific concurrency features

## Test Data
Generate synthetic logs in 3 sizes:
- **Small**: 10K lines (~1MB)
- **Medium**: 100K lines (~10MB)
- **Large**: 1M lines (~100MB)

Format: Realistic Apache/Nginx style logs
- 70% INFO messages
- 20% WARN messages
- 10% ERROR messages

## Metrics to Measure
1. **Execution Time**: Real, user, and system time
2. **Memory Usage**: Peak resident set size (RSS)
3. **CPU Usage**: Percentage utilization

## Benchmarking Process
- **Warmup**: 1 iteration (discarded) to account for JIT compilation
- **Measured Runs**: 5 iterations per language
- **Statistics**: Calculate min, max, average, median
- **Tool**: macOS `/usr/bin/time -l` for detailed metrics

## Deliverables
1. Complete implementations for all 16 languages
2. Synthetic log generator
3. Automated benchmark harness
4. Results stored in JSON format
5. Beautiful web UI displaying:
   - Leaderboard with sortable metrics
   - Animated bar chart race
   - Detailed per-language breakdowns
   - Visual comparisons

## Platform
- Target: macOS only
- No need for cross-platform compatibility

## Workflow
```bash
# Generate logs
python3 scripts/generate_logs.py

# Run benchmark
bash scripts/benchmark.sh

# View results
open web/index.html
```

## Success Criteria
- All 16 languages successfully implemented
- Fair and consistent benchmarking methodology
- Results captured and stored
- Engaging, informative web visualization
- Clear winner and insights about language trade-offs
