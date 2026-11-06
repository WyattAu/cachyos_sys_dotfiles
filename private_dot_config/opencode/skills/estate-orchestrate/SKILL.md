---
name: estate-orchestrate
description: |
  Delegation economics: decide when to work inline, use explore, or dispatch
  general/background subagents, and define the return contract so results
  come back compressed instead of as transcripts. Use when a task has 2+
  independent workstreams, when exploration would flood context, when
  running long builds/soaks in parallel with other work, or when the user
  says delegate, parallelize, spawn agents, or save context.
allowed-tools: read, grep, glob, bash, subagent
license: Apache-2.0
---

# estate-orchestrate

A subagent is a context firewall with a cost. Use it when the wall is worth
the overhead; never as a default.

## Decision table

| Situation | Choice |
|---|---|
| one known file, ≤2 edits | inline |
| locate code across many files | `explore` (quick/medium) |
| 3+ independent domains, no shared state | parallel subagents |
| long build/soak while other work continues | background subagent |
| needs judgement across many sources | `general` |
| binary triage / decompilation | `re` |
| anything requiring the user's live tabs | never delegate |

Rule: if the exploration would add more than ~500 lines to context and its
detail is not needed afterwards, delegate. If the answer needs the detail,
do it inline.

## Task contract (every dispatch)

```
goal:        one sentence, verifiable
inputs:      exact paths/commands, no "the repo"
constraints: what must not change (files, services, credentials)
return:      <format>; ≤15 lines, file:line pointers, no transcripts
stop:        when the goal is met or the budget is spent
```

Vague goal → vague result → re-work, which costs more than doing it
inline.

## Parallelism rules

- Dispatch only truly independent work: different files, different
  services, no shared mutable state.
- Read-only exploration parallelizes cleanly; concurrent writers do not.
  For write work, one agent per worktree.
- Batch the dispatches in one turn; do not stagger 30 seconds apart.
- Integrate results yourself: verify claims against the artifact, then
  commit once.

## Return contract

Demand, and pass through, only:
1. verdict (one line),
2. evidence pointers (file:line, command, hash),
3. what changed,
4. open questions / blockers.

Reject: pasted files, full logs, step-by-step narration, apologies.

## Anti-patterns

- Spawning a subagent to answer something one grep would settle.
- Parallel agents editing the same checkout.
- Accepting "done" from a subagent without its artifact.
- Re-running the subagent's work inline to double-check everything.
- Delegating interactively-visible state (browser tabs, live UI).
