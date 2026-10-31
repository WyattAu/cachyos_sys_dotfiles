/**
 * fleet-guard — OpenCode plugin for the WyattAu estate (V2 plugin API).
 *
 * Two hooks:
 *
 * 1. permission.evaluate — auto-allow read-only MCP tools (lean-lsp
 *    diagnostics, time, osint lookups) so they never prompt. Everything
 *    else falls through to the configured rules unchanged.
 *
 * 2. tool.execute.after — scan tool output for patterns that look like
 *    leaked credentials (AWS keys, private keys, API tokens) and warn
 *    before they reach the model's context.
 *
 * History: written against a draft single-event API as a plain object
 * export; OpenCode V2 rejected it on every config reload ("Plugin must
 * export a default definition with an id"). Ported to Plugin.define on
 * 2026-10-31, following the shapes proven by proof-loop.ts (event
 * mutation, not return values, in the permission hook).
 *
 * Deferred (was in the old docstring, never implemented): skill injection
 * in the clawdius directory. ctx.skill.transform is the V2 destination if
 * that lands. Deployed via chezmoi; edit the source, not the rendered copy.
 */

import { Plugin } from "@opencode/plugin"
import { appendFileSync, mkdirSync } from "node:fs"

// Tools that are safe to auto-allow: they read state, never modify it.
const READ_ONLY_PREFIXES = [
  "lean_diagnostic",
  "lean_goal",
  "lean_term_goal",
  "lean_hover",
  "lean_completions",
  "lean_local_search",
  "lean_file_outline",
  "lean_references",
  "lean_declaration_file",
  "lean_verify",
  "lean_minimal_hypotheses",
  "osint_list_sources",
  "dns_lookup",
  "dns_reverse",
  "whois_domain",
  "whois_ip",
  "crtsh_search",
  "geoip_lookup",
  "wayback_available",
  "bgp_asn",
  "bgp_ip",
  "time_",
]

// Patterns that look like leaked credentials in tool output.
const LEAK_PATTERNS = [
  /AKIA[0-9A-Z]{16}/, // AWS access key
  /-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----/, // private key block
  /ghp_[A-Za-z0-9_]{36,}/, // GitHub personal access token
  /gho_[A-Za-z0-9_]{36,}/, // GitHub OAuth token
  /sk-[A-Za-z0-9]{32,}/, // OpenAI/Anthropic key
  /xox[bpars]-[A-Za-z0-9-]{10,}/, // Slack token
]

// Pull every string field that could name the tool being evaluated. The
// evaluate-event schema has grown across builds (tool / action / resources);
// match against all of them rather than betting on one. Returns the first
// name that matches a read-only prefix, or null.
function matchedReadOnlyName(event: unknown): string | null {
  const e = event as { tool?: unknown; action?: unknown; resources?: unknown }
  const candidates: string[] = []
  if (typeof e.tool === "string") candidates.push(e.tool)
  if (typeof e.action === "string") candidates.push(e.action)
  if (Array.isArray(e.resources)) {
    for (const r of e.resources) if (typeof r === "string") candidates.push(r)
  }
  for (const c of candidates) {
    if (READ_ONLY_PREFIXES.some((p) => c.startsWith(p))) return c
  }
  return null
}

// Best-effort JSONL side-channel for diagnostics; never throws (same
// convention as proof-loop's debug()).
function debug(event: unknown) {
  try {
    mkdirSync("/tmp/opencode", { recursive: true })
    appendFileSync("/tmp/opencode/fleet-guard-events.jsonl", JSON.stringify(event) + "\n")
  } catch {}
}

// Tool results arrive as a string or a structured object. Extract the
// human-readable text from the shapes seen in practice:
//   string
//   { content: string } | { content: Array<{ type: "text", text }> }   (MCP)
//   { output: string } | { output: { exit, truncated, output: string } } (shell/bash)
function extractText(result: unknown): string | null {
  const seen: unknown[] = [result]
  const parts: string[] = []
  let guard = 0
  while (seen.length > 0 && guard < 8) {
    guard += 1
    const cur = seen.shift()
    if (typeof cur === "string") {
      parts.push(cur)
      continue
    }
    if (!cur || typeof cur !== "object") continue
    const o = cur as Record<string, unknown>
    if (typeof o.content === "string") parts.push(o.content)
    else if (Array.isArray(o.content)) seen.push(...o.content)
    if (typeof o.output === "string") parts.push(o.output)
    else if (o.output && typeof o.output === "object") seen.push(o.output)
    if (typeof o.text === "string") parts.push(o.text)
  }
  return parts.length > 0 ? parts.join("\n") : null
}

export default Plugin.define({
  id: "fleet-guard",

  async setup(ctx) {
    // -- permission.evaluate: read-only MCP tools never prompt --------------
    await ctx.permission.hook("evaluate", (event) => {
      if (event.effect !== "ask") return
      const tool = matchedReadOnlyName(event)
      if (!tool) return
      event.effect = "allow"
      event.message = `fleet-guard: read-only tool auto-allowed (${tool})`
    })

    // -- tool.execute.after: credential-leak scan ---------------------------
    let shapeProbed = false
    await ctx.tool.hook("execute.after", (event) => {
      const e = event as Record<string, unknown>
      if (!shapeProbed) {
        shapeProbed = true
        debug({
          at: Date.now(),
          probe: "execute.after event shape",
          keys: Object.keys(e),
          status: e.status,
          resultPreview: JSON.stringify(e.result)?.slice(0, 200),
        })
      }
      // Scan successful results and error messages alike: an echo of a
      // secret fails its command just as loudly as it succeeds.
      const candidates: string[] = []
      if (e.status === "completed") {
        const text = extractText(e.result)
        if (text) candidates.push(text)
      }
      if (e.status === "error" && e.error && typeof e.error === "object") {
        const msg = (e.error as { message?: unknown }).message
        if (typeof msg === "string") candidates.push(msg)
      }
      for (const text of candidates) {
        for (const pattern of LEAK_PATTERNS) {
          if (pattern.test(text)) {
            const alert = {
              at: Date.now(),
              alert: "possible-secret-in-tool-output",
              tool: e.tool,
              sessionID: e.sessionID,
              pattern: pattern.source,
              excerpt: text.match(pattern)?.[0]?.slice(0, 12) + "...",
            }
            debug(alert)
            console.warn(
              "fleet-guard: POSSIBLE SECRET IN TOOL OUTPUT — " +
                `pattern ${pattern.source} matched. ` +
                "Do not copy this output into a commit, issue, or report. " +
                "Rotate the credential if it is real.",
            )
            break
          }
        }
      }
    })
  },
})
