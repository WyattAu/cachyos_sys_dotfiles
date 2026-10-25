Run full fleet diagnostics.

1. `bash scripts/sys-check` from ~/.local/share/chezmoi (the hourly gate)
2. `mcp-doctor --format json` — per-server MCP diagnostics (gating)
3. `git -C ~/.local/share/chezmoi status` — config drift
4. `git -C ~/.local/share/chezmoi fetch origin && git -C ~/.local/share/chezmoi status` — remote drift
5. Check SSH agent: `ssh-add -l`
6. Check all managed repos are clean and pushed (chezmoi, clawdius, engineering-standards, mcp-doctor, detonate-mcp)

Report: a table of every check, its status, and any action needed.
If anything is failing, root-cause from the logs before proposing a fix.
