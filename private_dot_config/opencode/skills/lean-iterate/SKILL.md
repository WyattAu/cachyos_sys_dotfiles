---
name: lean-iterate
description: Lean 4 proof iteration using lean-lsp; goal states, tactic testing, mathlib search, and the verification ladder
compatibility: opencode
metadata:
  audience: agents
  workflow: math-proofs
  opencode/slash: "true"
---

## What I do

Accelerate Lean 4 proof iterations using the lean-lsp MCP server (22
tools) as the primary feedback channel; goal states, tactic testing,
and mathlib search without full lake builds.

## Prerequisites

- clawdius repo (has `lakefile.toml`, `lake-manifest.json`)
- elan installed (fleet-wide)
- lean-lsp MCP server enabled (auto-detects the project from CWD)

## Workflow

### Start of session

1. `lean_diagnostic_messages` on the target file; see current state
2. If `still_elaborating_lines` is present, WAIT (Lean is still working;
   this is not an error). Poll again.
3. If the file has zero diagnostics, the proof is already clean; pick
   a different target.

### Iterating on a proof

1. `lean_goal` at the tactic position; see the exact proof state
2. `lean_multi_attempt` with a tactic list; test candidates in-place
   without editing the file:
   `["simp", "omega", "decide", "exact Or.inl rfl"]`
3. If a tactic works, edit the file and verify with `lean_diagnostic_messages`
4. If nothing works, search:
   - `lean_local_search` (local declarations, fastest)
   - `lean_leansearch` (natural language → mathlib)
   - `lean_loogle` (type pattern → mathlib)
   - `lean_hammer_premise` (goal → premises for simp/aesop)

### Before committing

1. `lake build`; the full gate (43+ targets, 0 sorries)
2. `lean_verify` on new theorems; axiom check (catches unsound axioms)
3. Registry parse; `tomllib.load(...)` on the registry file

## Decision tree

| Situation | Tool |
|---|---|
| "What is the proof state here?" | `lean_goal` |
| "Will this tactic work?" | `lean_multi_attempt` |
| "Does this file have errors?" | `lean_diagnostic_messages` |
| "Does a lemma for X exist in mathlib?" | `lean_leansearch` |
| "What closes this goal?" | `lean_hammer_premise` |
| "Does this theorem use sorry/axioms?" | `lean_verify` |
| "Is the file clean?" | `lean_diagnostic_messages` (zero items = clean) |

## Slow files

Large files (like `host.lean` at 350+ lines) may return
`partial: true` + `still_elaborating_lines`; Lean is still working.
Poll again; it is NOT a dead server.

## What NOT to do

- Never use `sorry`; the build gate catches it and the loop protocol
  forbids it.
- Never edit the file before testing with `lean_multi_attempt`; the
  LSP gives faster feedback without disk writes.
- Never use `native_decide` without understanding WHY `decide` failed -
  it may be evaluating through an unreduced def, which is a different
  problem than "decide can't close it."
