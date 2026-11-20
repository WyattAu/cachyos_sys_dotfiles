---
name: estate-first
description: Search the WyattAu GitHub estate for existing implementations before writing new code — dogfood estate crates, skills, and patterns first, then public ecosystems, and only then write from scratch. Use when starting a new feature, utility, crate, script, integration, or any code that might already exist in the estate (aileron, clawdius, osint-kit, standards, dotfiles, and ~200 more repos under github.com/WyattAu).
---

# Estate First

Before writing new code, check whether the WyattAu estate already has it.
Redundant reimplementation is the estate's largest waste vector — every
crate added twice costs review, maintenance, audit surface, and CI time
forever.

## Search order

1. **Estate code search** (authoritative):
   ```
   gh search code --owner WyattAu "<keyword or symbol>"
   gh search repos --owner WyattAu "<topic>"
   ```
2. **Local dev tree** (211 checkouts, often ahead of origin):
   ```
   ls ~/dev/src/github.com/WyattAu/
   rg -l "<keyword>" ~/dev/src/github.com/WyattAu/ --type rust -g '!target'
   ```
3. **Estate crates already in-tree**: if the target repo depends on
   `aileron-*`, `clawdius-*`, or `standards` crates, check their exports
   before adding ANY new dependency — the module you need is often
   already a `pub use` away.
4. **Public ecosystems**: crates.io (`cargo search`), skills.sh, GitHub
   general.
5. **Write new code** only if steps 1-4 found nothing adaptable. If an
   estate crate almost fits, extend it (PR to that repo) rather than
   forking logic locally.

## Rules

- New helper fn in a repo that also has an estate `shared`/`core` crate?
  Put it in the estate crate, not the repo — one implementation, many
  consumers.
- New MCP tool? Check the target service's estate MCP server first
  (aileron-agent serves browser tools; osint-kit serves recon tools) —
  add a tool there rather than a new server.
- New skill? Check `~/.agents/skills/` and the ECC collection before
  authoring.
- When you find estate code that fits: USE it and say so in the
  commit/PR ("dogfooded clawdius-core FleetRouter"). When you find
  near-miss code: reference the gap in the PR so the owner can extend
  the original instead of the copy.
