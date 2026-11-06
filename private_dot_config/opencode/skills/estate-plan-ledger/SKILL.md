# Estate Plan Ledger

---
name: estate-plan-ledger
description: |
  Crash-proof, compaction-proof task state: an append-only markdown ledger
  with a status table, evidence pointers, and a bounded resume block. Use
  when a task will outlive one context window or one harness restart, when
  running multi-sprint programs, long builds, soaks, or migrations, or when
  the user says continue/resume after a break. Also use at handoff between
  agents or sessions.
allowed-tools: read, write, edit, bash
license: Apache-2.0
---

# estate-plan-ledger

The transcript is volatile; the ledger is not. If a restart would lose it,
it belongs on disk.

## File

`docs/plans/<slug>.md` (repo) or `/tmp/opencode/<slug>-plan.md` (ephemeral).
Append-only history, one mutable status table at the top.

```markdown
# <slug>

status: active | blocked | done
updated: <ISO date>  rev: <n>

## State
| # | Task | Status | Evidence | Next |
|---|------|--------|----------|------|
| 1 | extract crate core | done | `git log -1` abc123 |; |
| 2 | no-headed build | active | /tmp/build.log | fix cfg sites |

## Next action
<one sentence, executable now>

## Blocked
- <gate>: <external dependency>; <what unblocks it>

## Log
- <date> <what changed> <artifact>
```

## Rules

1. **Update the table before the work, not after.** Status changes are
   written when they happen; the log entry lands with the artifact.
2. **Evidence is a pointer**, never a transcript: commit hash, file:line,
   log path, test name.
3. **One next action.** If two are possible, the first is the next action
   and the second is a row.
4. **Bounded resume**: on restart read the table + next action only. Do not
   replay the log unless a decision depends on it.
5. **Blocked is a first-class status**, with the external dependency named.
   Never let a blocked item disappear into "in progress".
6. **Append-only log.** Corrections are new entries; history is not
   rewritten.
7. **Handoff block** when another agent or session continues:
   state table, next action, files that changed, commands that are safe to
   re-run, and what must not be touched.

## Re-injection

After compaction, restarts, or a model switch, the first turn must read the
ledger and restate in ≤5 lines: status, last artifact, next action. This is
cheaper than re-deriving state from tool history and avoids repeating
completed work.

## Anti-patterns

- Plans in chat only.
- Status updated in bulk at the end (drift by construction).
- Evidence rows containing pasted logs.
- Multiple "next" actions that silently drop the rest.
- Resume that re-runs completed steps to "check".
