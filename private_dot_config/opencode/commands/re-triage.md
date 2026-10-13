---
description: Static triage of a binary via the sandboxed RE agent (background)
agent: re
subagent: true
---

Perform a static triage of the binary at $1 using the radare2 MCP
server (escalate to Ghidra only if its tools connect).

If $2 is provided, focus the string/function analysis on that theme
(e.g. "persistence", "network", "license check").

Follow the triage order from your instructions and produce the report
in the required format. Do not execute the binary under any
circumstances; close the r2 session when done.
