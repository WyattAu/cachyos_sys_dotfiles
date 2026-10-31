// fleet-guard extractText + LEAK_PATTERNS regression test.
// Keep the two copies in sync (this file and the plugin); sys-check runs
// this against the plugin source. Shapes captured live 2026-10-31 from
// /tmp/opencode/fleet-guard-events.jsonl probe entries.
//
// Run: bun run tests/plugins/fleet-guard-extract.ts   (exit 0 = pass)

function extractText(result: unknown): string | null {
  const seen: unknown[] = [result]
  const parts: string[] = []
  let guard = 0
  while (seen.length > 0 && guard < 8) {
    guard += 1
    const cur = seen.shift()
    if (typeof cur === "string") { parts.push(cur); continue }
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

// Extracted from private_dot_config/opencode/plugins/fleet-guard.ts
const LEAK_PATTERNS = [
  /AKIA[0-9A-Z]{16}/,
  /-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----/,
  /ghp_[A-Za-z0-9_]{36,}/,
  /gho_[A-Za-z0-9_]{36,}/,
  /sk-[A-Za-z0-9]{32,}/,
  /xox[bpars]-[A-Za-z0-9-]{10,}/,
]

const hit = (s: string | null) => (s ? LEAK_PATTERNS.some((p) => p.test(s)) : false)

const shellShape = { output: { exit: 0, truncated: false, output: "probe: AKIAIOSFODNN7EXAMPLE (fake)" } }
const mcpShape = { content: [{ type: "text", text: "token: ghp_" + "A1b2C3d4E5f6G7h8I9j0K1l2M3n4O5p6q7r8" }] }
const strShape = "-----BEGIN RSA PRIVATE KEY-----"
const benign = { output: { exit: 0, output: "cargo test: 11 passed; 0 failed" } }
const emptyShape = {}

let fail = 0
for (const [name, input, want] of [
  ["shell shape", shellShape, true],
  ["mcp shape", mcpShape, true],
  ["string shape", strShape, true],
  ["benign shape", benign, false],
  ["empty shape", emptyShape, false],
] as const) {
  const got = hit(extractText(input))
  console.log(`${got === want ? "PASS" : "FAIL"} ${name}: match=${got}`)
  if (got !== want) fail += 1
}
process.exit(fail)
