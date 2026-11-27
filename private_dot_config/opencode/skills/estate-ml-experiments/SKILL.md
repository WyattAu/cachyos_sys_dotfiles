---
name: estate-ml-experiments
description: |
  ML experiment discipline for estate training runs: naming, config-first
  execution, seeds, baselines, champion tracking, artifact paths, GPU
  etiquette, crash handling; the four validation gates (instrument, data,
  canary, pre-registration); attribution, measurement. Use when
  launching, resuming, comparing, or reporting runs; when a run finishes
  or crashes; when deciding champion status; or the user says train, run,
  benchmark, eval, champion. Does not: model architecture design,
  dataset creation.
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

## Gates — validate before you spend (cheapest first)

Every gate is minutes of CPU and exists because skipping it cost hours of
GPU. Run them in order; never spend the expensive resource to test the
cheap thing.

1. **Instrument gate** (before any measurement): the binary that scores
   the experiment passes its selftest — rules consistency (perft),
   forced-move finding, legality probes, eval-sign battery. A known-bug
   TODO in a measurement path is a landmine: validate it or fix it
   before measuring. Cost ~60s. (Caught: three ladders scored on a
   searcher with four stacked bugs.)
2. **Data gate** (before training on any new shard/dataset): sample
   records and probe — is every policy target actually legal (against a
   trusted rules engine, not the generator), what is the target
   distribution, what is the current champion's match-rate on a sample
   batch. Cost ~2 min CPU. (Caught: a fine-tune whose policy targets
   were single-engine moves — it regressed the champion's policy head to
   a 3% match rate within 1,450 steps.)
3. **Canary bands** (first 500 steps + fixed intervals): write expected
   metric bands into the launch config; the run aborts or is flagged
   when metrics leave them. Catches silent design flaws mid-run: a
   match-rate falling 0.55 → 0.033 means the data contradicts the
   design, not that training is working.
4. **Pre-registration** (before launch): the script header states what
   result confirms and what falsifies the hypothesis. Catches
   experiments that do not test what they claim to test.

## Measurement discipline

- **Attribution**: every score recount prints its engine-attribution
  line and a per-engine game tally; cross-check both before a number
  enters the ledger. Three vs-champion entries were sign-flipped by
  reading an attribution line wrong.
- **Precision-matched comparisons**: ladders compare the same serving
  format (quantized-vs-quantized or fp32-vs-fp32). Serving format is
  part of the measurement — the quantization bonus measured +280 and
  inverted a training-method effect between precisions.
- **Absolute anchoring**: every champion gets an externally anchored
  absolute rating (limit-strength ladder vs a calibrated reference).
  In-house ladders drift and misattribute; the anchor catches both.
- **Value-target quality**: an eval head trained on raw human outcomes
  inherits human noise (a piece-up position is only ~60% in human
  games). Searches over human-noise-calibrated evals add no strength.
  Retarget evals to engine-verified win probabilities before searching.

## Long-run resilience

- Step-level checkpoint/resume is MANDATORY for runs longer than a few
  hours; max crash loss = one checkpoint interval, not the run.
- Disk headroom preflight before launch + an in-run guard (runs that die
  at a full disk corrupt artifacts and waste the run).
- Every wasted run gets a written root-cause and the gate that would
  have caught it — the gate list grows from the post-mortems.

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
- Measuring with an instrument that has a known-bug TODO in it.
- Training on a dataset that was never probed (targets, distribution,
  match-rate).
- A multi-hour run without checkpoint/resume.
- A verdict from a recount whose attribution line was not cross-checked.
- Comparing across serving formats and calling it a training delta.
- A fine-tune that touches weights the hypothesis says to leave alone.
