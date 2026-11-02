# Fleet Guard — OpenCode Plugin

Enforces the WyattAu estate's safety and hygiene rules at the OpenCode
platform level, so they apply to every session, every project, every
model — without relying on the model to follow system-prompt
instructions.

## What it does

| Hook | Behavior |
|------|----------|
| `permission.evaluate` | Auto-allow read-only MCP tools (lean-lsp diagnostics, OSINT DNS/WHOIS, time) so they never prompt. Everything else falls through to configured rules. |
| `tool.execute.after` | Scans tool output for leaked credentials (AWS keys, private keys, GitHub PATs, OpenAI keys, Slack tokens). Warns with the specific pattern matched. |

## What it does NOT do

- Does not block any tool call (that would require a `permission.evaluate` deny, which is reserved for future use).
- Does not scan every byte of output (only checks the `output` string against known credential patterns — not a full DLP solution).
- Does not prevent the model from generating credentials in its own output (that would need a `chat.message` hook, which is a different plugin).

## Installation

Chezmoi-managed: `chezmoi apply` places it at
`~/.config/opencode/plugins/fleet-guard.ts`.

## The credential-leak scanner

The LEAK_PATTERNS list catches the most common credential formats.
It is not exhaustive — if a new service uses a novel token format,
add a pattern here. The `console.warn` fires once per tool call
(breaks after the first match), so it won't spam for a large output.
