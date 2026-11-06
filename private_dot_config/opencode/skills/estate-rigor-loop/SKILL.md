---
name: estate-rigor-loop
description: |
  Evidence-first execution loop: hypothesis, cheapest falsifying test,
  verification ladder, labelled confidence, hard stop conditions. Use when
  fixing a bug, proving a claim, closing a gate, validating a migration, or
  any task where "looks right" is not acceptance. Use when a build or test
  must be trusted, when results are surprising, or when the user asks for
  proof, rigor, or root cause.
allowed-tools: read, grep, bash
license: Apache-2.0
---

# estate-rigor-loop

No claim without an artifact. No artifact without a command that could have
failed.

## Loop

1. **State the claim** in one falsifiable sentence.
2. **State the prediction** the claim makes ("build exits 0", "latency
   p50 < 400ms", "no unlabelled node in the AX tree").
3. **Run the cheapest test that could break it.** Cheapest first: compile →
   unit → integration → live system → formal proof.
4. **Record the artifact**: command, exit code, decisive line, path, or
   hash. If it cannot be recorded, it is not evidence.
5. **Label the result**: `measured` (command), `inferred` (reasoning over
   measured facts), `assumed` (neither). Assumptions are allowed but named.
6. **Stop or iterate.** Green with artifact → next task. Red → one
   hypothesis, one change, re-test. Two failed hypotheses → widen the
   evidence (logs, traces, bisect), never guess harder.

## Verification ladder

| Rung | Checks | Fails when |
|---|---|---|
| build | compiles, no warnings in CI profile | missing cfg, dead code |
| unit | targeted tests pass | logic, invariants |
| integration | cross-module / live service | wiring, protocol |
| live | real device, real browser, real data | environment, timing |
| formal | proof / model check | spec mismatch |

Never claim a higher rung than the artifact supports. "Tests pass" is not
"works on the phone".

## Rules

- **Reproduce before fixing.** A fix for an unreproduced bug is a guess.
- **One variable per change.** Batch changes only when independent and
  separately verified.
- **Fail closed.** Unsure state must error, not silently succeed.
- **Ask what would prove me wrong.** If nothing could, the claim is
  untestable and should be restated.
- **Timebox.** Two failed hypotheses or 20 minutes without new evidence →
  stop, summarise what is known, change strategy or escalate.
- **Never fake a gate.** Blocked is a valid, reportable state with a named
  external dependency.

## Evidence block (use verbatim in reports)

```
claim:      <one sentence>
prediction: <observable>
command:    <exact command>
result:     <exit code + decisive line>
class:      measured | inferred | assumed
```

## Anti-patterns

- Declaring done because the diff "looks right".
- Retrying a flaky test until green without explaining the flake.
- Editing the test, fixture, or threshold to match the bug.
- Reporting a gate as passed when it was skipped or timed out.
- Letting a fix land without the test that would have caught it.
