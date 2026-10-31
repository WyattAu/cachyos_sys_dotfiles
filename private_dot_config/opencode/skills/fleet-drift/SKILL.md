---
name: fleet-drift
description: Detect configuration drift across the WyattAu fleet; compare chezmoi-managed files against actual system state
compatibility: opencode
metadata:
  audience: agents
  workflow: infrastructure
  opencode/slash: "true"
---

## What I do

Check whether the fleet's managed configuration matches the actual
system state: chezmoi-rendered files, installed packages, enabled
services, MCP server surface, and the ansible-declared state.

## Workflow

1. **Render check**; `chezmoi apply --dry-run` and inspect what
   would change (this is the primary drift detector)
2. **Package drift**; compare `pacman -Q` against the host_vars
   package lists (common → arch_native → arch_only/cachyos → hostname)
3. **Service drift**; `systemctl list-units --state=running` against
   the services that should be running
4. **MCP surface**; compare the rendered opencode.jsonc server count
   against the expected count; check each server's binary is on PATH
5. **Git state**; each managed repo should be clean and pushed
   (chezmoi, clawdius, engineering-standards, mcp-doctor, detonate-mcp)
6. **Secret state**; `ls ~/.config/opencode/keys/`; which key files
   exist, are they 0600, is anything empty

## Output

A table: check | expected | actual | drift (yes/no) | action needed.
Then a prioritized remediation list.

## What NOT to do

- Never auto-fix drift without showing the diff first; a drifted file
  may contain manual changes the user made intentionally.
- Never `chezmoi apply --force` without explaining WHY the force was
  needed (it overwrites the target even if the user edited it).
