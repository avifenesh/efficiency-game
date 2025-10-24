<!-- GitHub Copilot / AI agent instructions for the "efficiency-game" repo -->
# Project-focused instructions for AI coding agents

These instructions explain the architecture, developer workflows, and repository-specific patterns so an AI can be immediately productive when editing or extending this project.

## Big picture
- This repo is a small multi-language benchmark / challenge named "efficiency-game". Implementations of the same task live under `implementations/` separated by language: `c/`, `nodejs/`, `python/`.
- A lightweight web front-end lives in `web/` (simple `index.html` + `app.js`) used for demonstration or visualization. Data fixtures and logs are in `data/` (see `results.json` and `synthetic/`).
- Other supporting scripts are under `scripts/` (benchmarking and log generation). Project notes and context live in `memory-bank/`.

## Key files to reference when reasoning
- `implementations/c/solution.c` — C implementation: reads a logfile, uses `pthread`s and manual string handling. Look here for low-level memory, threading, and I/O patterns.
- `implementations/c/build.sh` and `run.sh` — build and run helpers used by CI or benchmarks.
- `implementations/nodejs/solution.js` and `implementations/nodejs/run.sh` — Node solution and runner; useful to model async I/O patterns.
- `implementations/python/solution.py` and `implementations/python/run.sh` — Python solution and runner.
- `scripts/benchmark.sh` — orchestrates language comparisons; changes here affect how performance is measured.
- `web/app.js` and `web/index.html` — minimal UI; useful when generating example output or debugging visualization issues.
- `data/results.json` and `data/synthetic/` — sample inputs and expected outputs; use them for regression tests or examples.
- `memory-bank/*.md` — design notes, goals, and other human context that explain why things are implemented a certain way.

## Project-specific workflows and commands
- Each language directory contains a `run.sh` that demonstrates how the solution is executed. Prefer invoking those scripts when reproducing behavior:

```bash
cd implementations/c && ./run.sh    # compile+run C version
cd implementations/nodejs && ./run.sh
cd implementations/python && ./run.sh
```

- Use `scripts/benchmark.sh` to run cross-language benchmarks. Be conservative when changing the benchmark harness: it drives CI comparisons.

## Conventions and patterns to preserve
- The repository demonstrates direct, idiomatic implementations per language rather than a single shared library. Keep language implementations isolated under `implementations/`.
- Runners are shell scripts that compile or invoke the language-specific solution; follow the existing `run.sh` style (minimal dependencies, explicit paths).
- Data files are canonical inputs/outputs for the benchmark; do not hard-code paths — prefer using the existing `run.sh` patterns.
- In C code prefer explicit allocation/free and careful use of `strdup`, `realloc`, and `pthread` primitives — reviewers expect explicit memory management.

## Integration and external dependencies
- There are no heavy external package manifests in this repo. Node/Python solutions assume a standard runtime environment. C relies on a POSIX-compatible toolchain (gcc/clang, pthreads).
- The benchmark harness (`scripts/benchmark.sh`) may call these language runtimes directly. When adding dependencies, update README and the per-language `run.sh` to make install steps explicit.

## Typical AI tasks and examples (how to edit safely)
- Small bugfix in a language-specific file: modify only the file (or its `run.sh`) in `implementations/<lang>/` and run that `run.sh` to verify output changes.
- Performance improvements: profile using `scripts/benchmark.sh` and include microbenchmarks. For C, consider algorithmic changes or more efficient string scanning; keep threading model intact unless you update `run.sh` and document rationale in `memory-bank/`.
- Changes that affect cross-language comparability: update `scripts/benchmark.sh` and add a changelog note in `README.md` or `memory-bank/progress.md`.

## Example prompts for human reviewers
- "I updated `implementations/c/solution.c` to fix a buffer handling bug — please run `implementations/c/run.sh` and `scripts/benchmark.sh` to verify behavior and performance." 
- "I propose changing the benchmark harness to add a warm-up phase. This will affect all languages; see `scripts/benchmark.sh` and `implementations/*/run.sh` for required changes."

## What not to do
- Do not introduce heavy framework dependencies without documenting an install path (`run.sh` or README). This repo favors self-contained scripts.
- Avoid cross-cutting refactors that touch multiple language folders in a single PR unless the change is in `scripts/benchmark.sh` or `data/` and clearly improves comparability.

## Where to document major changes
- Add short rationale notes to `memory-bank/progress.md` and update `README.md` when changing benchmark semantics or adding runtime dependencies.

---
If anything in these instructions is unclear or you want more examples (tests, a CI workflow, or a suggested benchmark extension), tell me which area to expand and I will iterate.
