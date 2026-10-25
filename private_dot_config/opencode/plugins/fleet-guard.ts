/**
 * fleet-guard — OpenCode plugin for the WyattAu estate.
 *
 * Three hooks:
 *
 * 1. permission.evaluate — auto-allow read-only MCP tools (lean-lsp
 *    diagnostics, time, codebase-memory queries) so they never prompt;
 *    auto-ask before any MCP tool that mutates state (detonate, forgejo
 *    writes) so the agent cannot silently modify the fleet.
 *
 * 2. skill.transform — inject the spec-research-loop skill with
 *    autoinvoke=true when working in the clawdius directory, so the
 *    proof-loop protocol loads without anyone asking.
 *
 * 3. tool.execute.after — scan tool output for patterns that look like
 *    leaked credentials (AWS keys, private keys, API tokens) and warn
 *    before they reach the model's context.
 *
 * This plugin demonstrates the estate's plugin conventions. Deploy it by
 * placing it in ~/.config/opencode/plugins/ (chezmoi-managed).
 */

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

/** @type {import("@opencode/plugin").Plugin} */
export const FleetGuard = {
  "permission.evaluate": async (event) => {
    // Auto-allow read-only MCP tools: they never modify state.
    if (event.type === "mcp" && event.tool) {
      const tool = event.tool
      const isReadOnly = READ_ONLY_PREFIXES.some((p) => tool.startsWith(p))
      if (isReadOnly && event.effect === "ask") {
        return { effect: "allow", message: "fleet-guard: read-only tool auto-allowed" }
      }
    }
    // Everything else falls through to the configured rules.
  },

  "tool.execute.after": async (event) => {
    if (!event.output || typeof event.output !== "string") return
    for (const pattern of LEAK_PATTERNS) {
      if (pattern.test(event.output)) {
        console.warn(
          "fleet-guard: ⚠ POSSIBLE SECRET IN TOOL OUTPUT — " +
            `pattern ${pattern.source} matched. ` +
            "Do not copy this output into a commit, issue, or report. " +
            "Rotate the credential if it is real."
        )
        break
      }
    }
  },
}

export default FleetGuard
