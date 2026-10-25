# Fleet Rules (always in context)

- The chezmoi source is at ~/.local/share/chezmoi — edit the source, not the rendered files.
- `chezmoi apply --force` may be needed if KDE wrote to a managed file (plasmanotifyrc).
- Validation ladder: chezmoi apply --dry-run → targeted checks → full apply.
- The dev tree at ~/dev/src/github.com/WyattAu/ FLAPS (invisible windows on the btrfs).
  If a path suddenly doesn't exist, wait 30 seconds and retry. Files written during
  an invisible window may vanish — always verify after writing, and commit + push
  immediately when the tree is visible.
- All MCP server keys are in ~/.config/opencode/keys/ (0600 files, read at spawn).
- gitleaks, trivy, and the pentest toolkit are native binaries — run via shell.
- clawdius proofs: use the lean-lsp MCP server (22 tools) for fast feedback;
  lake build is the final gate only.
- mcp-doctor is the per-server diagnostic; sys-check is the hourly gate.
