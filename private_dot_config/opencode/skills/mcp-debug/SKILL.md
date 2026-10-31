---
name: mcp-debug
description: Debug MCP server connection failures and tool errors; root-cause from OpenCode logs, not guesses
compatibility: opencode
metadata:
  audience: agents
  workflow: infrastructure
  opencode/slash: "true"
---

## What I do

Debug MCP server connection failures, tool errors, and transport
issues. Every diagnosis starts from OpenCode's own log, not from
guessing.

## Workflow

### Step 1: Read the log

```sh
tail -c 200000 ~/.local/share/opencode/log/opencode.log | \
  grep 'mcp connect failed\|mcp transport error\|spawning process' | \
  grep 'server=<name>'
```

The log tells you exactly which step failed:
- **spawning process** → the command was launched
- **mcp connect failed** → the process started but didn't complete the handshake
- **mcp transport error** → the connection was established but broke

### Step 2: Classify the failure

| Log pattern | Root cause | Fix |
|---|---|---|
| `process exited with code 2` + quoting error | config command has unbalanced quotes | fix the command string in the config |
| `process exited with code 1` + module not found | package not installed or cache corrupted | persistent install (`bun add -g`) replaces bunx |
| `process exited with code 1` + "No such file" | binary not on PATH | install it or fix the PATH |
| `Connection closed` + no error detail | process started then died silently | run the command manually to see the real error |
| `timed out` | cold download exceeded startup timeout | prewarm the cache or increase timeout |
| `401` / `403` (remote) | credential missing or expired | authenticate via /mcps or check the token |

### Step 3: Verify the fix

Run the EXACT rendered command from the config (not a paraphrase):

```sh
# extract the command from the config
python3 -c "
import json; cfg = json.load(open('...'))
print(cfg['mcp']['servers']['<name>']['command'])"
```

Then run it by hand and send an initialize message. If the handshake
succeeds, the fix is correct. If not, the manual error output is the
real root cause.

## Decision rules

- A probe-verified fix that still fails in OpenCode means the SPAWN
  ENVIRONMENT differs from your shell. Check: PATH, HOME, and whether
  the config uses `{{ }}` templating that didn't expand.
- A server that lists tools but fails on every call has a CREDENTIAL
  issue, not a connection issue. Check the token/key separately.
- bunx servers are fragile on slow filesystems (bun itself warns about
  this). Persistent installs (`bun add -g`) are the definitive fix.

## What NOT to do

- Never restart OpenCode to "clear" an MCP error; the error will
  reproduce because the cause is in the config or environment.
- Never add a `timeout` increase without first confirming the root
  cause is actually a timeout, not a silent exit.
- Never mark a server as `disabled: true` to silence an error without
  documenting WHY it was disabled and HOW to re-enable it.
