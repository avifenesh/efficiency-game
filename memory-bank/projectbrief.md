# Project Brief: Language Efficiency Race

## Project Name
Language Efficiency Race (efficiency-game)

## Core Purpose
A comprehensive benchmark comparing the execution efficiency of 13+ programming languages through a real-world concurrent log anomaly detection task. The goal is to provide objective, reproducible performance metrics that answer "Which language is fastest for real-world tasks?"

## Primary Objectives
1. **Fair Performance Comparison**: Measure execution time, memory usage, and CPU utilization across multiple languages
2. **Real-World Task**: Use practical concurrent log processing (not synthetic micro-benchmarks)
3. **Statistical Validity**: Multiple iterations with warmup for accurate results
4. **Interactive Visualization**: Beautiful web dashboard to explore results
5. **Easy Extension**: Simple framework for adding new language implementations

## Target Audience
- Software engineers evaluating language choices
- Technical decision-makers comparing performance
- Programming language enthusiasts
- Students learning about language performance characteristics

## Success Criteria
1. All implementations produce identical results (JSON with error/warning counts)
2. Benchmark runs consistently across different environments
3. Results are automatically published to GitHub Pages
4. Adding a new language takes < 30 minutes
5. Dashboard is visually appealing and easy to interpret

## Core Task Specification
Each language implementation must:
- Read log files using concurrent/parallel processing
- Scan for ERROR and WARN patterns with word boundaries
- Count total occurrences
- Output JSON: `{"errors": N, "warnings": N, "total": N}`
- Exit with code 0 on success

## Non-Goals
- Not a general-purpose benchmark suite
- Not optimizing for specific hardware
- Not comparing developer productivity or code maintainability
- Not testing I/O-bound or network-bound workloads specifically

## Current Status
- **13 languages implemented**: C, C++, C#, Elixir, Java, Julia, Kotlin, Nim, Node.js, PHP, Python, Ruby, Rust
- **3 log sizes**: Small (10K lines), Medium (100K lines), Large (1M lines)
- **Web dashboard**: Fully functional with interactive charts and rankings
- **GitHub Pages**: Auto-deployed from docs/ directory
- **Benchmark system**: Mature with warmup, cooldown, and statistical analysis

## Repository
https://github.com/avifenesh/efficiency-game
