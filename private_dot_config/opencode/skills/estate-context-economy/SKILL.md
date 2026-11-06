# Estate Context Economy

---
name: estate-context-economy
description: |
  Context and token budget discipline for every task: locate before reading,
  cap every tool output, keep durable state in files, delegate noisy work.
  Use when a task spans many files, when output is large (logs, tests, JSON,
  diffs, dependency trees, snapshots), when context is near compaction, or
  when the user asks about token usage, cost, or speed. Load before any
  multi-step sweep, long build, or multi-repo job.
allowed-tools: read, grep, glob, bash
license: Apache-2.0
---

# estate-context-economy

Context is working memory and the bill. Every token kept must still be
useful at the end of the task.

## Budget model

| Item | Rough cost | Policy |
|---|---|---|
| file read | ~1.3 tokens per line | read windows, not files |
| test/log dump | 5k–50k tokens | grep counts, tail only |
| tool schema prompt | fixed per call | fewer calls, batch independent ones |
| subagent return | capped by contract | ≤15 lines + pointers |
| skill load | 300–900 tokens | load one, not five |

Rule of thumb: no single retrieval may consume more than ~10% of the
remaining context. If it would, narrow it first.

## Rules

1. **Locate before read.** `grep -n` the symbol, then read ±40 lines around
   the hit. Read a whole file only when it is new to the task and under
   ~400 lines.
2. **Cap every command.** `| head -40`, `| tail -20`, `rg -c`, `--jq`,
   `wc -l`, `du -sh`, `sort | uniq -c`. Unknown-size output gets filtered
   before it is seen, then widened once if needed.
3. **Batch independent calls** in one block. Serialize only real
   dependencies (write → verify, build → test).
4. **Delegate noise.** Broad searches, huge build logs, multi-repo sweeps,
   binary inspection → subagent. Require a conclusion plus `file:line`
   pointers, never a transcript.
5. **Durable state lives on disk.** Plan ledger, gate status, evidence
   paths, PIDs, log locations. Re-derive from pointers instead of
   re-reading or re-running.
6. **Answers are deltas.** Verdict first, changed lines plus two lines of
   context, never re-paste what the user already has. Tables for enumerable
   facts, prose for causal chains.
7. **Compact deliberately.** Before long work, write the state table
   (task | status | evidence | next). After compaction or a restart, read
   that table first; not the transcript.

## Decision table

| Need | Do not | Do |
|---|---|---|
| find a symbol | read the whole file | `grep -n` then a window |
| test failures | paste the full log | `grep -E "FAILED|error\[" \| head -20` |
| large JSON | `cat` | `--jq '.[0:5]'` |
| repo survey | open 50 files | `rg --files \| head`, three targeted greps |
| verify a claim | assume | run the one command that can falsify it |
| check a build | re-run for the log tail | `tail -20 logfile` |

## Anti-patterns

- Reading a 2,000-line file "to understand it".
- Re-running a command whose output is already in context.
- Pasting full diffs, logs, or trees into chat, commits, or reports.
- Spawning parallel subagents that return transcripts.
- Loading several skills when one covers the task.

## Check

Before each tool call ask: will this output change the next action? If not,
do not make the call. After each turn ask: what is the smallest summary that
preserves the decision?
