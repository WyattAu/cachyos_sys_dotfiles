# Global rules

## MCP tool selection

Prefer MCP tools over guessing:

- **context7**: fetch current library/framework/API docs before writing or debugging code against a library. Resolve the library ID first, then query one concept per call.
- **gh_grep**: find real-world usage of an API or pattern across public GitHub code before inventing syntax.
- **duckduckgo.search**: current events, release notes, error messages with no obvious cause. Follow up with **fetch** to read a specific page.
- **fetch**: read a known URL when built-in webfetch is unavailable or truncated.
- **git** MCP: prefer for status/diff/log/staging inspection; use built-in shell for anything exotic.
- **github**: issues, PRs, releases, actions. Always paginate (5–10 items), set `minimal_output` where available, and call `get_me` before permission-sensitive operations.
- **memory**: store durable facts about the user, environment, and project decisions (entities + observations). Check it when context suggests prior work; keep entries small. Do not store secrets or ephemeral task state.
- **sequential-thinking**: for multi-step debugging or architecture decisions only — not routine edits.
- **playwright**: general browser automation/screenshots. The **aileron** tools are for the Aileron browser specifically; if aileron tools error with "connection refused", the Aileron browser is not running — say so instead of retrying.
- **time**: any "today", deadline, or timezone computation; never guess dates.

## Session hygiene

- Context is finite: paginate, cap output lengths, and avoid dumping large tool results.
- Old tool outputs may be pruned by compaction — re-read a file before editing it after long gaps.
