# Product Context: Language Efficiency Race

## Why This Project Exists

### The Problem
- Developers frequently debate "which programming language is fastest" but lack objective data
- Most benchmarks are synthetic micro-benchmarks that don't reflect real-world usage
- Performance discussions often rely on anecdotes rather than measured evidence
- No single source compares many languages on the same real-world task with fair methodology

### The Solution
A transparent, reproducible benchmark suite that:
- Tests a realistic concurrent workload (log anomaly detection)
- Measures multiple dimensions (time, memory, CPU)
- Provides beautiful visualization of results
- Makes methodology completely transparent
- Allows community to verify and extend

## Problems It Solves

### For Engineers
- **Decision Making**: Objective data for language selection decisions
- **Performance Expectations**: Understand typical performance characteristics
- **Learning**: See how different languages approach concurrency

### For Language Communities
- **Fair Comparison**: Equal treatment with warmup for JIT languages
- **Transparency**: Open-source methodology anyone can audit
- **Recognition**: Showcase language strengths in specific domains

### For Students/Learners
- **Education**: Learn about language performance characteristics
- **Examples**: See concurrent programming patterns in 13+ languages
- **Practical Insight**: Move beyond "Hello World" to real benchmarks

## How It Should Work

### User Experience Flow

#### 1. Setup Phase
```
User runs: python3 scripts/generate_logs.py
→ Creates synthetic log files at 3 scales
→ Immediate feedback on file creation
```

#### 2. Benchmark Phase
```
User runs: ./scripts/benchmark.sh
→ Visual progress for each language
→ Builds compiled languages automatically
→ Runs warmup iterations for JIT languages
→ Executes 15 measured iterations per language
→ Real-time feedback: "Iteration 1/15... ✓ (1.23s, 45MB)"
→ Generates data/results.json
→ Auto-updates web/index.html with results
```

#### 3. Results Phase
```
User opens: web/index.html
→ Sees beautiful dashboard with:
   - Interactive time/memory charts
   - Rankings by different metrics
   - Detailed per-language cards
   - Sortable data tables
→ Can also view on GitHub Pages
```

### Key User Experience Principles

1. **Simplicity**: Three commands maximum to go from zero to results
2. **Transparency**: Every step explains what it's doing
3. **Visual Feedback**: Clear success/failure indicators with color
4. **Automation**: Results automatically update web dashboard
5. **Flexibility**: Can benchmark individual languages or all at once

## Expected Behavior

### Benchmark Execution
- **Fairness**: All languages tested on identical hardware sequentially
- **Warmup**: JIT languages (Java, C#, Kotlin, Node.js, Julia, Elixir) get warmup runs
- **Cooldown**: 2-second pause between iterations to reduce thermal throttling
- **Timeout**: 5-minute limit per run to catch infinite loops
- **Multiple Iterations**: 15 runs for statistical validity
- **Error Handling**: Graceful handling of missing toolchains

### Results Presentation
- **Rankings**: Automatically sorted by performance
- **Statistics**: Min, max, avg, median for all metrics
- **Visualization**: Charts make patterns immediately obvious
- **Accessibility**: Results embedded in static HTML (no backend needed)
- **Sharing**: GitHub Pages provides permanent, shareable URL

### Adding New Languages
- Create directory: `implementations/<language>/`
- Write solution following standard interface
- Create `run.sh` (and `build.sh` if compiled)
- Add to LANGUAGES array in benchmark.sh
- Run benchmark - automatic integration

## User Goals

### Primary Goals
1. Compare language performance objectively
2. Understand tradeoffs between languages
3. Make informed technology decisions
4. Learn about concurrent programming patterns

### Secondary Goals
1. Contribute new language implementations
2. Experiment with optimization techniques
3. Use as teaching material for performance discussions
4. Showcase language capabilities

## Design Philosophy

### Core Values
- **Objectivity**: No bias toward any language
- **Reproducibility**: Anyone can run and verify results
- **Transparency**: Methodology fully documented
- **Practicality**: Real-world task, not synthetic benchmarks
- **Beauty**: Results should be pleasant to explore

### Trade-offs Made
- **Completeness vs Simplicity**: Focus on one task type (log processing) done well
- **Depth vs Breadth**: Many languages, single workload
- **Automation vs Control**: Opinionated defaults, but extensible
- **Performance vs Fairness**: Accept some overhead for fair warmup/cooldown

## Success Metrics

### Quantitative
- 13+ languages implemented ✓
- < 30 minutes to add new language ✓
- < 5 minutes total benchmark runtime (medium logs) ✓
- 100% consistent JSON output across languages ✓

### Qualitative
- Users can understand results without documentation ✓
- Dashboard is visually appealing ✓
- Results are shareable and discussable ✓
- Methodology withstands scrutiny ✓
