# AGENTS.md — Rules for AI agents editing this repository

This is a chezmoi + Ansible fleet repo for Arch/CachyOS/WSL machines.
Read `README.md` first for architecture. The rules below are lessons
that cost real debugging time — follow them.

## Hard rules

1. **`.chezmoidata/*.toml`: tables go LAST.** In TOML, every key after a
   `[table]` header belongs to that table. A table placed mid-file
   silently swallows all following scalars (this broke every `kde_*`
   template once). After any `.chezmoidata` edit, run
   `chezmoi data | grep '<a-scalar-you-did-not-touch>'` to confirm it
   still exists.
2. **`scripts/` files are NOT templates.** They are executed straight
   from the source dir (`~/.local/share/chezmoi/scripts/`) and symlinked
   into `~/.local/bin`. `{{ }}` in them is literal text (this silently
   broke the Telegram alert once). No chezmoi data is available there.
3. **`~/.config/opencode/opencode.jsonc` must parse as JSONC, and it is the
   ONLY global opencode config.** A `run_onchange` verifier parses it on
   every `chezmoi apply`, and CI renders + parses it hermetically (root
   `flake.nix` → `nix build .#checks.x86_64-linux.opencode-config -L`).
   Run that nix check locally before pushing config changes. The file is
   native OpenCode V2 shape (`mcp.servers`, `disabled`, per-server
   `timeout {catalog, execution}`, `providers`/`settings`,
   `agents`/`permissions`). A stray hand-rolled `opencode.json` beside it
   is fleet-forbidden (`.json` vs `.jsonc` merge precedence is
   undocumented); `sys-check` flags it. V1-only shapes stay supported by
   upstream but must not be reintroduced here (known: flat `mcp` maps,
   `enabled`, `startup` timeouts, agent `mode`/`tools`, compaction
   `prune`). Cross-agent skills live in `dot_agents/skills` →
   `~/.agents/skills`; per-machine binaries that a server needs are gated
   OFF in that host's `~/.config/chezmoi/chezmoi.toml`
   `[data.opencode.mcp]`, never by editing the template.
4. **Test flags against the real binary, not the docs.** Examples of
   docs-vs-reality gaps already hit: r2mcp `-s` takes ONE dir (colon
   lists and repeated flags break opening); GhidraMCP v2 ships a nested
   extension zip + Python wheel, not a bridge script; Ghidra 12.x
   lowercased `application.version` in `application.properties`.
5. **Sys-check must stay green.** `scripts/sys-check` validates the
   fleet hourly and alerts via Telegram. Anything it checks (opencode
   binaries, MCP backends, Ghidra extension, playwright cache, docker
   image) is load-bearing — update the check when you change the thing.

## Workflow

- Validation ladder: `ansible-playbook --syntax-check` (ansible/) →
  `chezmoi execute-template` (templates) → `bash -n` (scripts) →
  `nix build .#checks.x86_64-linux.opencode-config -L` (config) →
  `sys-sync --dry-run` → real `sys-sync` → `sys-check` exits 0.
- Package changes go in `host_vars/` layer files (common → arch_native →
  arch_only/cachyos → hostname), never in the playbook. Official repos
  (extra) > chaotic-aur > AUR.
- Ansible user-level tasks use `become: true, become_user: "{{ user }}"`
  with `HOME: "/home/{{ user }}"` in the environment.
- The opencode role self-verifies (final `assert` block) and auto-detects
  GhidraMCP releases via redirect + expanded-assets scraping — do not
  replace that with the GitHub API (rate-limits took it down once).
- `scripts/sys-save` runs a Nix push gate when config-relevant files
  change; `git push` by hand bypasses it — prefer `sys-save`.

## Known-state notes (Oct 2026)

- GhidraMCP extension (12.1.4-built) is verified compatible with Arch
  ghidra 12.1.2 via headless import; the role warns on every sync until
  versions match. Expected — do not "fix" the warning.
- The fleet has `bun` + `pnpm` + `nodejs-lts` but NO `npm`/`npx`. Use
  `bunx` for npm-packaged MCP servers.
- `wsl-dev` runs the full stack (Nix excluded); `.chezmoiignore.tmpl`
  handles the desktop-only exclusions.
