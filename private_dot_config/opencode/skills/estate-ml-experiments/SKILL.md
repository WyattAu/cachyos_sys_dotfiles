---
name: estate-ml-experiments
description: |
  ML experiment discipline for the estate's training runs: naming,
  config-first execution, seeds, baselines, champion tracking, artifact
  paths, GPU etiquette, crash handling. Use when launching, resuming,
  comparing, or reporting training runs; when a run finishes or crashes;
  when deciding champion status; on checkpoint disk pressure; or the
  user says train, run, benchmark, eval, champion. Not for model
  architecture design or dataset creation.
allowed-tools: read, bash, grep
license: Apache-2.0
---

# estate-ml-experiments

An experiment is a claim with evidence, not a process. Everything about a
run must be reconstructible from its artifacts alone.

## Naming and paths

- Results: `<model>_<variant>_s<seed>_w<window>_<tag>.json` — every axis
  that changes conclusions is in the filename, machine-parseable.
- Configs are written INTO the result file at launch (full resolved
  config, not the CLI args), so a result is reproducible without the
  terminal history.
- One directory per campaign; checkpoints under it, never in the repo
  root. Champion binaries get a stable path recorded in the memory graph.

## Launch discipline

1. **Config-first**: the config object is the single source of truth;
   CLI flags override it explicitly and the override is printed at start.
2. **Seeds**: fixed, recorded; report mean ± spread over seeds for any
   claim that matters. A single-seed win is a hypothesis, not a result.
3. **Baseline first**: never launch a challenger without the current
   champion's number on the same machine, same eval, same day.
4. **GPU etiquette**: check `nvidia-smi` for other agents' runs before
   launching; one training process per GPU unless memory says otherwise;
   long runs detached (`setsid nohup`, log file, PID recorded).
5. **Smoke pass**: 1-2 minutes of training before the full run — crashes
   at minute 40 are the thing this prevents.

## During the run

- Log metrics at fixed intervals to the result file (append, not rewrite).
- Watchdog: record PID + log path; a run without a live log line for 2×
  the expected interval is dead — check before assuming training.
- Never `pkill` python estate-wide; PID-target the exact run.

## Champion tracking

- Champion = the current best per a named metric on a named eval,
  recorded with: binary path, seed, eval date, score, and the run file.
- A challenger replaces the champion only when it beats the champion on
  the SAME eval, same method, with seed evidence.
- Record the change in the memory graph ("champion replaced: <old> ->
  <new> by <score> on <date>, run <file>") — the graph is the ledger.
- Keep the previous champion binary until the new one has survived a
  second eval; rollback is cheaper than regret.

## Disk pressure (checkpoints are the estate's biggest consumer)

- Keep: champion, latest, best-per-variant. Delete: middle checkpoints
  past the keep-set. Check `df` before long runs; runs that die at 98%
  full corrupt artifacts.
- Prefer metrics-in-result-file over checkpoint spam; checkpoint only at
  milestones.

## Reporting

- One line per run: name, seed(s), eval, score, delta vs champion,
  verdict (champion / rejected / inconclusive).
- Rejected runs are reported, not hidden — negative results gate the
  next hypothesis.
- Crash reports include: last log line, exit signal, steps completed,
  and whether partial artifacts are usable.

## Anti-patterns

- Launching on a GPU another agent is using.
- Result files without embedded configs.
- Single-seed champion claims.
- Deleting the old champion binary the moment the new one wins once.
- A training run whose only record is a terminal that got closed.
