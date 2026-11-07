---
name: estate-mcp-authoring
description: |
  Build estate MCP servers in Rust from the proven kit pattern: stdio
  line-JSON framing, tools/list schema, call dispatch, drop-in API
  compatibility with the server being replaced, live test before swap.
  Distilled from four shipped servers (memory-kit, github-kit,
  mcp-sentinel serve, filesystem-kit). Use when creating a new MCP
  server, replacing a third-party one, adding tools to an existing kit,
  or debugging MCP framing/handshake issues. Does not cover remote
  (HTTP/SSE) servers or OAuth flows.
allowed-tools: read, write, bash
license: Apache-2.0
---

# estate-mcp-authoring

An estate MCP server is one Rust binary, one file of dispatch, no
runtime deps. Four servers shipped from this exact shape; follow it
unless there is a measured reason not to.

## The pattern (four data points)

1. **Scaffold**: new repo `WyattAu/<name>-kit`, Cargo with
   `serde_json` (+ crates the domain needs), `[profile.release] lto = true`,
   Apache-2.0 LICENSE, README with the tool list and run command.
2. **Framing**: JSON-RPC 2.0, one request per stdin line, one response per
   stdout line. stdout is the protocol — diagnostics go to stderr.
3. **Methods**: `initialize` (protocolVersion 2024-11-05, serverInfo),
   `notifications/*` ignored, `ping`, `tools/list` (name + description +
   inputSchema per tool), `tools/call` (result = content: [{type:"text",
   text: JSON-stringified payload}], isError on failure).
4. **Dispatch**: one `call_tool(name, args)` returning
   `Result<Value, String>` — Ok serializes into content, Err becomes
   isError text. Unknown tool → error.
5. **Config**: register in the opencode template (chezmoi source) as a
   local server running the installed binary; never reference target/ paths.

## Replacement discipline (replacing a third-party server)

1. **Inventory the API first** from the live server (tools/list through
   the harness, not from docs): names, argument names, shapes.
2. **Drop-in compatibility**: same tool names, same argument names, same
   result semantics — agents must not notice the swap.
3. **Add the guard the third-party one lacks** (memory-kit: nothing;
   filesystem-kit: allowed-roots guard; github-kit: shaped responses).
   One improvement per server, shipped, not a redesign.
4. **Test the real workflow live before the swap**: real API/repos/files,
   every tool, plus the failure paths (missing entity, denied path,
   HTTP error text surfaced as isError).
5. **Swap in place under the old server key** (namespace stays
   `tools.<old-name>.*`) — or register alongside when validating; the
   old entry is retired only after a parity window.
6. **Migrate data with an import command** (`<name>-kit import <file>`),
   idempotent, original export untouched, counts reported.

## Failure-mode hardening (each bit us once)

- `unwrap_or(0)` on execute hides FK/constraint errors: decide explicitly
  and enable `PRAGMA foreign_keys=ON` where relations matter.
- External processes (adb, gh) block forever when the peer dies: wrap in
  `timeout` (or a bounded wait) — never raw blocking calls.
- Remote HTTP servers: pin tool hashes with mcp-sentinel; un-pinned
  remote definitions are a standing supply-chain advisory.
- Response shaping is part of the API: slim objects, excerpted bodies —
  tool output is agent context budget (see estate-context-economy).

## Ship checklist

- [ ] handshake: initialize → serverInfo with version
- [ ] tools/list: full catalog, correct inputSchema
- [ ] every tool: happy path + one failure path, live
- [ ] drop-in: old tool names/args preserved
- [ ] guard/improvement shipped and documented in README
- [ ] registered in the opencode template, `chezmoi apply`, catalog shows it
- [ ] repo pushed; README lists tools, run command, storage/keys

## Anti-patterns

- Writing an HTTP/SSE server when the agent harness speaks stdio.
- Inventing new tool names for a drop-in replacement.
- Unbounded output (read the whole 2GB log into one response).
- Blocking forever on a dead external process.
- Hand-editing the generated opencode.jsonc instead of the template.
