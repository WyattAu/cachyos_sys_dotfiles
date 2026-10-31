---
name: estate-keys
description: Handle credentials and API keys in the WyattAu estate; key-file pattern, no secrets in dotfiles, spawn-time reads
compatibility: opencode
metadata:
  audience: agents
  workflow: credentials
  opencode/slash: "true"
  opencode/autoinvoke: "true"
---

## What I do

Enforce the estate's credential rules whenever API keys, tokens, or
secrets are being added, moved, or referenced by MCP servers or scripts.

## The rules (non-negotiable)

1. **No secret ever enters a dotfile, config template, or git repo.**
   Not in .chezmoidata, not in opencode.jsonc, not in a comment.
2. **Keys live in 0600 files under ~/.config/opencode/keys/<name>**
   (directory 0700). MCP wrappers read them at spawn time via bash
   (`test -s "$f" && export VAR="$(cat "$f")"`); the same pattern as
   the github server's `gh auth token` read.
3. **Why key files over shell exports**: desktop-launched OpenCode does
   not inherit fish rc files, so export-based keys silently miss half
   the launch contexts. Files work everywhere.
4. **OAuth-preferred when the service offers it** (sentry, linear,
   firecrawl, virustotal use remote OAuth endpoints; authenticate once
   via /mcps, no key file needed).
5. **Failures must name the missing credential**: a wrapper that cannot
   find its key prints which file it expected, then exits; never a
   silent degradation, never a generic error.

## When touching credentials

- New MCP server needing a key → key file + wrapper read + a comment in
  private_dot_config/opencode/private_opencode.jsonc.tmpl pointing at
  the key path.
- Never echo a key value into logs, reports, or commit messages.
- The direct-API validity check (curl with the key) is allowed; printing
  the key itself is not.
