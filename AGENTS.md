# AGENTS Playbook

Guidance for the rotating crew of human and AI helpers building the Language Efficiency Race. Each agent should know their lane, how to hand off work, and what “done” means so contributions stay fast and consistent.

## Operating Principles
- Anchor every decision to the benchmark goal: fair, repeatable comparisons of 16 languages processing concurrent log workloads.
- Prefer updating the memory bank (`memory-bank/*.md`) before inventing new patterns. If a new insight matters, add it there as part of the task.
- Keep the standardized interface sacred (`./run.sh <log> → JSON output`). Deviation creates extra glue code downstream.
- Automate once, reuse everywhere. Scripts live in `scripts/`, measurements in `data/`, UI under `web/`.
- Document notable trade‑offs inline (short comments) so future agents can reason without guesswork.

## Agent Roster & Lanes

### 1. Archivist
- **Mission**: Maintain the authoritative context in the memory bank and high-level docs (`README.md`, `memory-bank/` files).
- **Inputs**: New architectural decisions, measurement methodology tweaks, UI principles.
- **Outputs**: Updated briefs, context docs, decision logs; call out unresolved questions in `memory-bank/progress.md`.
- **Definition of Done**: Stakeholders can reconstruct the “why” of any change from the docs alone.

### 2. Implementation Engineer
- **Mission**: Build or fix per-language solutions in `implementations/<lang>/` following the concurrency + JSON contract.
- **Inputs**: Task file path, language conventions from `techContext.md`, benchmark expectations.
- **Outputs**: `solution.*`, `run.sh`, and when needed `build.sh`; lightweight README for language-specific notes.
- **Definition of Done**: `./run.sh data/synthetic/<size>.log` returns valid JSON, exits 0, and leverages concurrent processing.

### 3. Benchmark Conductor
- **Mission**: Own orchestration logic (`scripts/benchmark.sh`, helpers) and keep metrics trustworthy.
- **Inputs**: Available implementations, measurement requirements (`/usr/bin/time -l`), hardware constraints.
- **Outputs**: Reliable builds, warmup handling, error handling, `data/results.json` schema stability.
- **Definition of Done**: One command runs all languages, handles failures gracefully, and produces structured metrics consumed by the UI.

### 4. Data Storyteller
- **Mission**: Translate `data/results.json` into compelling visuals in `web/` (HTML/CSS/JS, Chart.js).
- **Inputs**: Results schema, product context, design tokens in `techContext.md`.
- **Outputs**: Responsive leaderboard, charts, annotations explaining insights.
- **Definition of Done**: Opening `web/index.html` immediately surfaces rankings, trends, and caveats without touching the console.

### 5. Ops & Toolsmith
- **Mission**: Provide infrastructure glue—install scripts, verification tooling, helper utilities (`scripts/*.sh`, `scripts/*.py`).
- **Inputs**: Pain points flagged by other agents (e.g., repeated setup steps, flaky env checks).
- **Outputs**: Deterministic scripts, CI hooks, lint/format aids, environment verifiers.
- **Definition of Done**: New contributors can bootstrap, validate, and run benchmarks with minimal manual steps.

### 6. Quality Analyst
- **Mission**: Validate correctness, fairness, and performance claims before publishing results or UI updates.
- **Inputs**: Latest implementations, benchmark output, suspected regressions.
- **Outputs**: Test plans, repro steps, issue notes in `memory-bank/progress.md`, failing cases turned into actionable fixes.
- **Definition of Done**: Each language’s metrics are reproducible; discrepancies are documented with hypotheses or assigned follow-ups.

## Collaboration Rituals
- **Kickoff**: Start work by scanning `memory-bank/activeContext.md` and `progress.md` for priorities or blockers.
- **Handoffs**: Summarize what changed, where it lives, and remaining risks inside PR descriptions or commit messages; mirror key points into the relevant memory-bank doc when strategic.
- **Verification**: When touching code, run the narrowest meaningful test (unit, `run.sh`, or `scripts/benchmark.sh --language <name>` when available) and record the command + outcome in your notes/PR.
- **Post-Task Update**: If new knowledge impacts multiple agents (e.g., measurement anomaly, UI schema change), add a short note to `progress.md` under “New Learnings”.

## Quick Reference
- **Source of Truth**: `README.md` for newcomers, `memory-bank/` for deep context.
- **Data Contracts**:
  - Log files: `data/synthetic/{small,medium,large}.log`
  - Benchmark output: `data/results.json`
- **Tooling**: `/usr/bin/time -l` for metrics, `python3 scripts/generate_logs.py` for data, `scripts/benchmark.sh` for orchestration.
- **UI Stack**: Vanilla JS + Chart.js, Inter/SF font stack, 8px spacing scale.

Stay within your lane, but leave breadcrumbs so the next agent can sprint from where you stop.
