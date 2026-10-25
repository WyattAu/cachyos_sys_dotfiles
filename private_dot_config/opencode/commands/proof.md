Iterate on a Lean 4 proof in the clawdius repo.

Target file and theorem: $ARGUMENTS

Use the lean-lsp MCP server (22 tools) as the PRIMARY feedback channel —
NOT `lake env lean` single-file checks (30s+ each).

1. `lean_goal` at the proof position — see the exact goal state
2. `lean_multi_attempt` with candidate tactics — test in-place:
   ["simp", "omega", "decide", "exact Or.inl rfl", "induction x"]
3. If a tactic works, edit and verify with `lean_diagnostic_messages`
4. If nothing works:
   - `lean_local_search` (local declarations)
   - `lean_leansearch` (natural language → mathlib)
   - `lean_loogle` (type pattern → mathlib)
   - `lean_hammer_premise` (goal → premises for simp/aesop)
5. Verify with `lean_verify` (axiom check — catches unsound axioms)

Rules (from clawdius AGENTS.md):
- No sorry, ever
- decide needs CLOSED goals (unfold defs first)
- _ wildcard in cases leaves the variable ABSTRACT
- Compute a concrete example before stating a list theorem
- Probe the negation before trusting a proof
- Ship the counter-witness with the property

Final gate: `lake build` (45 targets, 0 sorries) + registry tomllib parse.
