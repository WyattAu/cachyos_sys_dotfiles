/**
 * proof-loop — autonomous plan → research → prove → implement → test → validate
 * iteration loop for OpenCode, driven by the harness (not by model obedience).
 *
 * How it works
 *   /loop start [args]   begin a loop in this session
 *   /loop status         current phase, budget, gate history
 *   /loop pause          stop auto-advancing (state kept, /loop start resumes)
 *   /loop stop           kill the loop
 *
 * The plugin owns the state machine. When the session goes idle, it:
 *   1. checks budget (tokens/cost/wall-clock/iterations) — exceeded → wrap-up turn
 *   2. runs the phase's gate ITSELF (lake build, cargo, TLC — exit codes, not promises)
 *      gate failure → same-phase retry prompt with the output tail (max N retries)
 *      gate pass    → advance to the next phase and prompt for it
 *   3. loop state lives in plugin storage + a session instruction entry, so
 *      auto-compaction can never lose the phase machine.
 *
 * Unattended safety: while a loop is active on a session, permission prompts
 * ("ask" rules, e.g. git push) are auto-DENIED and recorded — reported at wrap-up.
 *
 * Project config (optional): <project>/.opencode/proof-loop.json
 *   {
 *     "phases": ["plan", "research", "prove", "implement", "test", "validate"],
 *     "budget": { "tokens": 4000000, "cost": 25.0 },
 *     "maxIterations": 4, "maxPhaseFails": 3, "maxMinutes": 180,
 *     "gates": { "prove": [ { "run": "lake build", "timeoutSecs": 900,
 *                             "failOn": ["error:", "sorry"] } ] }
 *   }
 * Gates are replaced, not merged. Without config, gates auto-detect:
 *   Lean (lakefile*) → lake build | TLA+ (*.tla) → SANY + TLC | cargo | bun test
 *
 * Deployed via chezmoi: ~/.local/share/chezmoi/private_dot_config/opencode/plugins/
 */

import { Plugin } from "@opencode/plugin"
import { exec } from "node:child_process"
import { existsSync, mkdirSync, appendFileSync, readFileSync, readdirSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

// ---------------------------------------------------------------------------
// types & defaults
// ---------------------------------------------------------------------------

type Phase = string

interface Gate {
  name: string
  run: string
  timeoutSecs: number
  failOn: string[] // substrings; a hit in combined output fails the gate
}

interface GateResult {
  name: string
  ok: boolean
  detail: string // short human-readable result
}

interface LoopState {
  sessionID: string
  directory: string
  status: "running" | "wrapping" | "paused" | "done"
  stopReason?: string
  phaseIdx: number
  phases: Phase[]
  iteration: number
  maxIterations: number
  budgetTokens?: number
  budgetCost?: number
  maxPhaseFails: number
  maxMinutes: number
  fails: number
  startedAt: number
  updatedAt: number
  requestDone: boolean
  deferred: { action: string; resources: string[] }[]
  gateHistory: { at: number; phase: string; ok: boolean; detail: string }[]
}

const DEFAULT_PHASES: Phase[] = ["plan", "research", "prove", "implement", "test", "validate"]
const MAX_PHASE_FAILS = 3
const MAX_MINUTES = 180
const MAX_ITERATIONS = 4
const IDLE_DEBOUNCE_MS = 1500

const budgetedTokens = (s: { tokens?: { input?: number; output?: number; reasoning?: number; cache?: { write?: number; read?: number } } }) =>
  (s.tokens?.input ?? 0) + (s.tokens?.output ?? 0) + (s.tokens?.reasoning ?? 0) + (s.tokens?.cache?.write ?? 0)

const lastIdleAt = new Map<string, number>() // per-session debounce
const advancing = new Set<string>() // per-session mutex

function debug(event: unknown) {
  // Best-effort JSONL side-channel for diagnostics; never throws.
  try {
    const f = "/tmp/opencode/proof-loop-events.jsonl"
    mkdirSync("/tmp/opencode", { recursive: true })
    appendFileSync(f, JSON.stringify(event) + "\n")
  } catch {}
}

function log(state: LoopState | null, msg: string) {
  const tag = `[proof-loop${state ? ` ${state.sessionID.slice(0, 10)} it${state.iteration} ${state.phases[state.phaseIdx]}` : ""}]`
  console.log(`${tag} ${msg}`)
  debug({ at: Date.now(), sessionID: state?.sessionID, phase: state?.phases[state.phaseIdx], iteration: state?.iteration, msg })
}

function logFile(directory: string, line: unknown) {
  try {
    const dir = join(directory, ".loop")
    mkdirSync(dir, { recursive: true })
    appendFileSync(join(dir, "events.jsonl"), JSON.stringify(line) + "\n")
  } catch {}
}

// ---------------------------------------------------------------------------
// config & gates
// ---------------------------------------------------------------------------

interface ProjectConfig {
  phases?: Phase[]
  budget?: { tokens?: number; cost?: number }
  maxIterations?: number
  maxPhaseFails?: number
  maxMinutes?: number
  gates?: Record<string, Gate[]>
}

function readConfig(directory: string): ProjectConfig {
  try {
    const p = join(directory, ".opencode", "proof-loop.json")
    if (existsSync(p)) return JSON.parse(readFileSync(p, "utf8"))
  } catch (e) {
    debug({ at: Date.now(), msg: `config parse failed: ${e}` })
  }
  return {}
}

function hasLean(directory: string): boolean {
  return ["lakefile.toml", "lakefile.lean", "lean-toolchain"].some((f) => existsSync(join(directory, f)))
}

function hasCargo(directory: string): boolean {
  return existsSync(join(directory, "Cargo.toml"))
}

function tlaFiles(directory: string): string[] {
  try {
    return readdirSync(directory).filter((f) => f.endsWith(".tla")).slice(0, 10)
  } catch {
    return []
  }
}

function tlaJar(): string | null {
  const candidates = [
    process.env.TLA2TOOLS_JAR,
    join(homedir(), "tools", "tla", "tla2tools.jar"),
    "/usr/share/java/tla2tools.jar",
  ]
  for (const c of candidates) if (c && existsSync(c)) return c
  return null
}

function detectGates(phase: Phase, directory: string): Gate[] {
  const gates: Gate[] = []
  const lean = hasLean(directory)
  const cargo = hasCargo(directory)
  const tla = tlaFiles(directory)

  if (phase === "prove" || phase === "validate") {
    if (lean) gates.push({ name: "lean-build", run: "lake build", timeoutSecs: 900, failOn: ["error:", "declaration uses 'sorry'"] })
    if (tla.length > 0) {
      const jar = tlaJar()
      if (!jar) {
        gates.push({
          name: "tla-toolchain",
          run: `echo "TLA+ specs present (${tla.join(", ")}) but tla2tools.jar not found — set TLA2TOOLS_JAR or install to ~/tools/tla/" && exit 1`,
          timeoutSecs: 10,
          failOn: [],
        })
      } else {
        for (const f of tla) {
          gates.push({ name: `tla-sany:${f}`, run: `java -cp "${jar}" tla2sany.SANY "${f}"`, timeoutSecs: 120, failOn: ["***Errors: "] })
          const cfg = f.replace(/\.tla$/, ".cfg")
          if (existsSync(join(directory, cfg))) {
            gates.push({ name: `tlc:${f}`, run: `java -cp "${jar}" tlc2.TLC -deadlock -fpmem 0.9 "${f}"`, timeoutSecs: 900, failOn: ["Error:", "Errors:"] })
          }
        }
      }
    }
  }
  if (phase === "implement" || phase === "validate") {
    if (cargo) gates.push({ name: "cargo-check", run: "cargo check --workspace --quiet", timeoutSecs: 900, failOn: ["error"] })
    if (lean && !cargo) gates.push({ name: "lean-build", run: "lake build", timeoutSecs: 900, failOn: ["error:", "declaration uses 'sorry'"] })
  }
  if (phase === "test" || phase === "validate") {
    if (cargo) gates.push({ name: "cargo-test", run: "cargo test --workspace --quiet", timeoutSecs: 1200, failOn: ["error", "FAILED", "panicked"] })
    if (existsSync(join(directory, "package.json"))) {
      try {
        const pkg = JSON.parse(readFileSync(join(directory, "package.json"), "utf8"))
        if (pkg?.scripts?.test) gates.push({ name: "bun-test", run: "bun run test", timeoutSecs: 600, failOn: ["error", "fail "] })
      } catch {}
    }
    if (lean && !cargo && phase === "test") gates.push({ name: "lean-test", run: "lake env lean CheckTests.lean 2>/dev/null || true", timeoutSecs: 300, failOn: [] })
  }
  // plan / research: soft phases, no executable gate by design
  return gates
}

function runGate(gate: Gate, cwd: string): Promise<GateResult> {
  return new Promise((resolve) => {
    exec(
      gate.run,
      { cwd, timeout: gate.timeoutSecs * 1000, maxBuffer: 4 * 1024 * 1024, env: { ...process.env, TERM: "dumb" } },
      (err, stdout, stderr) => {
        const out = `${stdout ?? ""}\n${stderr ?? ""}`
        if (err && err.killed) return resolve({ name: gate.name, ok: false, detail: `timeout after ${gate.timeoutSecs}s` })
        const failHit = gate.failOn.find((f) => out.includes(f))
        if (err) {
          const tail = out.trim().split("\n").slice(-12).join("\n").slice(-1200)
          return resolve({ name: gate.name, ok: false, detail: `exit ${err.code ?? "?"}${failHit ? ` (matched "${failHit}")` : ""}\n${tail}` })
        }
        if (failHit) return resolve({ name: gate.name, ok: false, detail: `output matched "${failHit}"` })
        return resolve({ name: gate.name, ok: true, detail: "ok" })
      },
    )
  })
}

async function runPhaseGates(phase: Phase, directory: string, cfg: ProjectConfig): Promise<GateResult[]> {
  const gates = (cfg.gates?.[phase] ?? detectGates(phase, directory)).map(
    (g, i): Gate => ({ name: g.name || `gate-${i + 1}: ${g.run.slice(0, 40)}`, run: g.run, timeoutSecs: g.timeoutSecs, failOn: g.failOn }),
  )
  if (gates.length === 0) return [{ name: "(none)", ok: true, detail: "no executable gate for this phase/project" }]
  const results: GateResult[] = []
  for (const g of gates) {
    const r = await runGate(g, directory)
    results.push(r)
    if (!r.ok) break // stop at first failing gate; retry prompt shows why
  }
  return results
}

// ---------------------------------------------------------------------------
// prompts
// ---------------------------------------------------------------------------

function recap(state: LoopState): string {
  const done = state.phases.slice(0, state.phaseIdx).join(" → ")
  return `[proof-loop] iteration ${state.iteration + 1}/${state.maxIterations} — phase ${state.phases[state.phaseIdx].toUpperCase()}${done ? ` (this iteration: ${done} ✓)` : ""}`
}

const PHASE_PROMPTS: Record<string, (state: LoopState) => string> = {
  plan: (s) => `${recap(s)}

PHASE: plan. Write the iteration plan to \`.loop/plan.md\` (create the dir):
- the single most valuable unit of work for THIS iteration, scoped to fit one pass of research → prove → implement → test → validate
- acceptance criteria per phase, concretely checkable
- what "done" means for the iteration goal
Read AGENTS.md / repo docs first so the plan fits house rules. Do NOT implement anything. When the plan file is written, end your turn — the harness gates and advances the loop.`,

  research: (s) => `${recap(s)}

PHASE: research. Resolve the plan's unknowns from REAL sources — specs, docs, upstream code in this repo — not training-data memory alone. Record findings with file/URL citations in \`.loop/research.md\`. If research invalidates the plan, revise \`.loop/plan.md\` accordingly. End your turn when done.`,

  prove: (s) => `${recap(s)}

PHASE: prove. Do the formal proof work for the planned change.
- Lean: use the lean-lsp MCP tools (lean_goal, lean_multi_attempt, lean_diagnostic_messages, lean_verify) as your feedback loop — NOT repeated full lake builds; the harness runs \`lake build\` as the gate after your turn.
- TLA+: edit/extend the spec; the harness runs SANY/TLC as the gate.
- NO \`sorry\` — a sorry survives \`lake build\` and FAILS the gate.
- Probe the negation before trusting a proof. Follow repo AGENTS.md proof rules.
End your turn when lean-lsp shows your files clean — the gate runs after.`,

  implement: (s) => `${recap(s)}

PHASE: implement. Make the planned change. Keep edits minimal, typed, consistent with surrounding code. Commit locally at a clean checkpoint with a clear message. NEVER push (unattended loop — pushes are auto-denied). End your turn when the build would plausibly pass; the harness runs it as the gate.`,

  test: (s) => `${recap(s)}

PHASE: test. Add or adjust tests covering the implemented change (happy path + the regression this change fixes). The harness runs the project suite as the gate after your turn, so optimize for the suite's rules, not ad-hoc runs. End your turn when done.`,

  validate: (s) => `${recap(s)}

PHASE: validate. Final pass for this iteration:
1. Re-read \`.loop/plan.md\` acceptance criteria and check each against the actual diff/state.
2. Write a short report to \`.loop/validate-${s.iteration + 1}.md\`: what was proven/implemented/tested, gate results, defects found, deferred items.
3. If the OVERALL loop goal is achieved, call the \`loop_control\` tool with {"action":"done","note":"why"}.
Otherwise just end your turn — the harness validates gates and starts the next iteration.`,
}

const RETRY_PROMPT = (state: LoopState, results: GateResult[]) => `${recap(state)}

GATE FAILED in phase ${state.phases[state.phaseIdx]} (attempt ${state.fails}/${state.maxPhaseFails}):
${results.filter((r) => !r.ok).map((r) => `- ${r.name}: ${r.detail}`).join("\n")}

Fix the failure and end your turn — the gate re-runs after. Do not mark done while a gate is red.`

const WRAPUP_PROMPT = (state: LoopState, why: string) => `[proof-loop] LOOP STOPPING — ${why}

Write a wrap-up (also to \`.loop/handoff.md\`):
- state of each phase this iteration: done / partial, with evidence
- artifacts produced (\`.loop/*\`, proofs, commits — list commit hashes)
- deferred permission-blocked actions: ${state.deferred.length ? JSON.stringify(state.deferred) : "none"}
- exactly what a future session should pick up first
Then end your turn. The loop will not prompt again.`

// ---------------------------------------------------------------------------
// plugin
// ---------------------------------------------------------------------------

export default Plugin.define({
  id: "proof-loop",

  async setup(ctx) {
    const load = (sessionID: string): Promise<LoopState | undefined> => ctx.storage.get(`loop/${sessionID}`) as Promise<LoopState | undefined>
    const save = (state: LoopState) => ctx.storage.set(`loop/${state.sessionID}`, state as unknown as Record<string, unknown>)

    async function syncEntry(state: LoopState) {
      try {
        const entryApi = (ctx.session as unknown as { instructions?: { entry?: { put: (i: unknown) => Promise<void>; remove: (i: unknown) => Promise<void> } } }).instructions?.entry
        if (!entryApi) {
          debug({ at: Date.now(), msg: "instructions.entry API unavailable in this build — skipping context sync" })
          return
        }
        const used = await usedTokens(state)
        const entry = [
          `proof-loop: ${state.status} | iteration ${state.iteration + 1}/${state.maxIterations} | phase ${state.phases[state.phaseIdx]} (${state.phaseIdx + 1}/${state.phases.length})`,
          `budget: ${used.tokens}${state.budgetTokens ? `/${state.budgetTokens}` : ""} tok, $${used.cost}${state.budgetCost ? `/${state.budgetCost}` : ""} | gate fails: ${state.fails}/${state.maxPhaseFails}`,
          state.deferred.length ? `deferred asks: ${state.deferred.map((d) => d.action).join(", ")}` : null,
          `control: loop_control tool {action:"done"} ends the loop; the harness advances phases after each idle turn.`,
        ].filter(Boolean).join("\n")
        await entryApi.put({ sessionID: state.sessionID, key: "proof-loop", value: entry })
      } catch (e) {
        debug({ at: Date.now(), msg: `syncEntry failed: ${e}` })
      }
    }

    async function clearEntry(sessionID: string) {
      try {
        const entryApi = (ctx.session as unknown as { instructions?: { entry?: { remove: (i: unknown) => Promise<void> } } }).instructions?.entry
        if (!entryApi) return
        await entryApi.remove({ sessionID, key: "proof-loop" })
      } catch {}
    }

    async function usedTokens(state: LoopState): Promise<{ tokens: number; cost: number }> {
      try {
        const info = await ctx.session.get({ sessionID: state.sessionID }) as unknown as {
          tokens?: { input?: number; output?: number; reasoning?: number; cache?: { write?: number } }
          cost?: number
          location?: { directory?: string }
          directory?: string
        }
        if (info?.location?.directory) state.directory = info.location.directory
        return { tokens: budgetedTokens(info), cost: info.cost ?? 0 }
      } catch {
        return { tokens: 0, cost: 0 }
      }
    }

    async function dispatch(state: LoopState, text: string) {
      log(state, `→ prompt: ${text.split("\n")[0].slice(0, 90)}`)
      logFile(state.directory, { at: Date.now(), phase: state.phases[state.phaseIdx], iteration: state.iteration, event: "prompt", text: text.slice(0, 120) })
      await ctx.session.prompt({ sessionID: state.sessionID, text })
    }

    // -- the state machine step, run on every session.idle -------------------
    async function advance(sessionID: string) {
      const state = await load(sessionID)
      if (!state || state.status === "done" || state.status === "paused") return
      if (advancing.has(sessionID)) return
      advancing.add(sessionID)
      try {
        const cfg = readConfig(state.directory)
        const used = await usedTokens(state)

        // budget / limits
        const overTokens = state.budgetTokens != null && used.tokens >= state.budgetTokens
        const overCost = state.budgetCost != null && used.cost >= state.budgetCost
        const overMinutes = Date.now() - state.startedAt > state.maxMinutes * 60_000

        if (state.status === "wrapping") {
          state.status = "done"
          state.updatedAt = Date.now()
          await save(state)
          await clearEntry(sessionID)
          log(state, `done (${state.stopReason ?? "wrapped"})`)
          return
        }
        if (state.requestDone) {
          state.status = "wrapping"
          state.stopReason = "model declared the goal achieved"
          await save(state)
          await syncEntry(state)
          await dispatch(state, WRAPUP_PROMPT(state, "the model declared the goal achieved via loop_control"))
          return
        }
        if (overTokens || overCost || overMinutes) {
          const why = overTokens ? `token budget reached (${used.tokens} ≥ ${state.budgetTokens})` : overCost ? `cost budget reached ($${used.cost} ≥ $${state.budgetCost})` : `wall-clock limit (${state.maxMinutes} min)`
          state.status = "wrapping"
          state.stopReason = why
          await save(state)
          await syncEntry(state)
          await dispatch(state, WRAPUP_PROMPT(state, why))
          return
        }

        // gates for the current phase
        const phase = state.phases[state.phaseIdx]
        const results = await runPhaseGates(phase, state.directory, cfg)
        const failed = results.filter((r) => !r.ok)
        for (const r of results) {
          state.gateHistory.push({ at: Date.now(), phase, ok: r.ok, detail: r.detail.slice(0, 200) })
          logFile(state.directory, { at: Date.now(), phase, iteration: state.iteration, event: r.ok ? "gate-pass" : "gate-fail", gate: r.name, detail: r.detail.slice(0, 300) })
        }
        state.gateHistory = state.gateHistory.slice(-50)

        if (failed.length > 0) {
          state.fails += 1
          if (state.fails >= state.maxPhaseFails) {
            state.status = "paused"
            state.stopReason = `phase ${phase}: gate failed ${state.fails}× — needs human: ${failed[0].detail.slice(0, 150)}`
            await save(state)
            await syncEntry(state)
            await dispatch(state, `${recap(state)}\n\nGATE FAILED ${state.fails}× — loop PAUSED for human review:\n${failed[0].name}: ${failed[0].detail}\n\nDo not retry. Summarize the blocker in \`.loop/handoff.md\` and end your turn.`)
            log(state, `paused: ${state.stopReason}`)
            return
          }
          await save(state)
          await syncEntry(state)
          await dispatch(state, RETRY_PROMPT(state, results))
          log(state, `gate fail (${state.fails}/${state.maxPhaseFails}): ${failed[0].name}`)
          return
        }

        // advance
        state.fails = 0
        if (state.phaseIdx + 1 >= state.phases.length) {
          state.iteration += 1
          if (state.iteration >= state.maxIterations) {
            state.status = "wrapping"
            state.stopReason = `iteration limit (${state.maxIterations}) reached with all gates green`
            await save(state)
            await syncEntry(state)
            await dispatch(state, WRAPUP_PROMPT(state, state.stopReason))
            return
          }
          state.phaseIdx = 0
          log(state, `iteration ${state.iteration} complete → next iteration`)
        } else {
          state.phaseIdx += 1
        }
        state.updatedAt = Date.now()
        await save(state)
        await syncEntry(state)
        await dispatch(state, PHASE_PROMPTS[state.phases[state.phaseIdx]]?.(state) ?? `${recap(state)}\n\nPHASE: ${state.phases[state.phaseIdx]}. Do the work for this phase, then end your turn.`)
      } catch (e) {
        debug({ at: Date.now(), sessionID, msg: `advance error: ${e}` })
      } finally {
        advancing.delete(sessionID)
      }
    }

    // -- events ---------------------------------------------------------------
    const controller = new AbortController()
    void (async () => {
      try {
        // NOTE: no `types` option — the server-side filter is unreliable in
        // 2.0.32; filter manually below. Turn-end is signaled by
        // session.execution.* events in this build (`session.idle` exists in
        // the newer API spec but is NOT emitted here).
        for await (const ev of ctx.event.subscribe({ signal: controller.signal })) {
          const raw = ev as unknown as Record<string, unknown>
          const rawType = String(raw.type ?? "")
          let outcome: string | undefined
          if (rawType === "session.execution.succeeded") outcome = "succeeded"
          else if (rawType === "session.execution.failed") outcome = "failed"
          else if (rawType === "session.execution.interrupted") outcome = "interrupted"
          else continue
          const data = (raw.data ?? {}) as Record<string, unknown>
          const sessionID = (data.sessionID ?? (raw.properties as Record<string, unknown> | undefined)?.sessionID) as string | undefined
          if (!sessionID) continue
          // ownership: this plugin is instantiated once per known location,
          // and execution events carry no location — resolve the session's
          // directory and only let the instance living there advance the loop
          // (prevents N instances double-running gates and prompts).
          let evDir: string | undefined
          try {
            const info = (await ctx.session.get({ sessionID })) as unknown as { location?: { directory?: string }; directory?: string }
            evDir = info?.location?.directory ?? info?.directory
          } catch {}
          if (evDir && evDir !== ctx.location.directory) continue

          const now = Date.now()
          if (now - (lastIdleAt.get(sessionID) ?? 0) < IDLE_DEBOUNCE_MS) continue
          lastIdleAt.set(sessionID, now)

          const state = await load(sessionID)
          debug({ at: Date.now(), msg: "idle-state-check", sessionID, outcome, status: state?.status ?? "NO-STATE", phase: state ? state.phases[state.phaseIdx] : undefined })
          if (!state || state.status === "done" || state.status === "paused") continue

          if (outcome === "interrupted") {
            state.status = "paused"
            state.stopReason = "interrupted by user"
            await save(state)
            await syncEntry(state)
            log(state, "paused (user interrupt)")
            continue
          }
          if (outcome === "failed") {
            state.status = "paused"
            state.stopReason = "turn failed (provider/model error) — /loop start to resume"
            await save(state)
            await syncEntry(state)
            log(state, `paused (turn failed)`)
            continue
          }
          void advance(sessionID)
        }
      } catch (e) {
        debug({ at: Date.now(), msg: `event loop error: ${e}` })
      }
    })()

    // -- model-facing control tool -------------------------------------------
    await ctx.tool.transform((editor) => {
      editor.add({
        name: "loop_control",
        description:
          "Proof-loop control. action=done: declare the loop's overall goal achieved — the harness stops after this turn and asks for a wrap-up. action=status: returns the current loop state JSON.",
        input: {
          type: "object",
          properties: {
            action: { type: "string", enum: ["done", "status"], description: "done = goal achieved, stop the loop; status = report state" },
            note: { type: "string", description: "short reason, required for done" },
          },
          required: ["action"],
          additionalProperties: false,
        },
        execute: async (input, context) => {
          const args = input as { action: "done" | "status"; note?: string }
          const state = await load(context.sessionID)
          if (!state) return { content: "No active proof-loop in this session." }
          if (args.action === "status") {
            const used = await usedTokens(state)
            return {
              content: JSON.stringify(
                {
                  status: state.status,
                  phase: state.phases[state.phaseIdx],
                  iteration: `${state.iteration + 1}/${state.maxIterations}`,
                  tokens: used.tokens,
                  cost: used.cost,
                  fails: state.fails,
                  deferred: state.deferred,
                  recentGates: state.gateHistory.slice(-5),
                },
                null,
                2,
              ),
            }
          }
          state.requestDone = true
          await save(state)
          log(state, `model requested done: ${args.note ?? ""}`)
          return { content: "Acknowledged. Finish your current step; the loop will wrap up after this turn." }
        },
      })
    })

    // -- unattended permission guard ------------------------------------------
    await ctx.permission.hook("evaluate", async (event) => {
      if (event.effect !== "ask") return
      const state = await load(event.sessionID)
      if (!state || state.status === "done") return
      event.effect = "deny"
      event.message = "proof-loop: unattended run — mutating 'ask' actions are deferred to the human. Record the need and work around it."
      state.deferred.push({ action: event.action, resources: [...(event.resources ?? [])] })
      state.deferred = state.deferred.slice(-20)
      await save(state)
      log(state, `deferred: ${event.action} ${JSON.stringify(event.resources ?? []).slice(0, 80)}`)
    })

    // -- /loop command ----------------------------------------------------------
    await ctx.command.transform((editor) => {
      editor.add({
        name: "loop",
        description: "proof-loop: start | status | pause | stop  [—budget-tokens N] [—budget-cost X] [—max-iterations N] [—phases a,b,c]",
        execute: async ({ sessionID, prompt }) => {
          const argv = (prompt.text ?? "").trim().split(/\s+/).filter(Boolean)
          const sub = argv.shift() ?? "status"

          const flag = (name: string): string | undefined => {
            const i = argv.indexOf(name)
            return i >= 0 ? argv[i + 1] : undefined
          }

          let state = await load(sessionID)

          if (sub === "stop") {
            if (!state) return
            state.status = "done"
            state.stopReason = "stopped by /loop stop"
            await save(state)
            await clearEntry(sessionID)
            try {
              await ctx.session.interrupt({ sessionID, resume: false })
            } catch {}
            log(state, "stopped by user")
            return
          }

          if (sub === "pause") {
            if (!state || state.status === "done") return
            state.status = "paused"
            state.stopReason = "paused by /loop pause"
            await save(state)
            await syncEntry(state)
            log(state, "paused by user")
            return
          }

          if (sub === "status") {
            if (!state) {
              console.log("[proof-loop] no loop in this session")
              return
            }
            const used = await usedTokens(state)
            const report = {
              status: state.status,
              phase: `${state.phases[state.phaseIdx]} (${state.phaseIdx + 1}/${state.phases.length})`,
              iteration: `${state.iteration + 1}/${state.maxIterations}`,
              tokens: used.tokens,
              cost: used.cost,
              stopReason: state.stopReason,
              fails: `${state.fails}/${state.maxPhaseFails}`,
              deferred: state.deferred.length,
              recentGates: state.gateHistory.slice(-5).map((g) => `${g.ok ? "✓" : "✗"} ${g.phase}: ${g.detail.slice(0, 60)}`),
            }
            console.log("[proof-loop]", JSON.stringify(report, null, 2))
            await syncEntry(state)
            return
          }

          // start / resume
          const cfg = readConfig(state?.directory ?? ".")
          const existing = state && state.status !== "done"
          if (existing && state) {
            state.status = "running"
            state.stopReason = undefined
            await save(state)
            await syncEntry(state)
            log(state, `resumed at ${state.phases[state.phaseIdx]}`)
            await dispatch(state, PHASE_PROMPTS[state.phases[state.phaseIdx]]?.(state) ?? `${recap(state)}\n\nContinue the ${state.phases[state.phaseIdx]} phase, then end your turn.`)
            return
          }

          const directory = await (async () => {
            try {
              const info = (await ctx.session.get({ sessionID })) as unknown as { location?: { directory?: string }; directory?: string }
              return info?.location?.directory ?? info?.directory ?? process.cwd()
            } catch {
              return process.cwd()
            }
          })()

          const phases = flag("--phases")?.split(",").map((p) => p.trim()) ?? cfg.phases ?? DEFAULT_PHASES
          const budgetTokens = Number(flag("--budget-tokens") ?? cfg.budget?.tokens ?? NaN) || undefined
          const budgetCost = Number(flag("--budget-cost") ?? cfg.budget?.cost ?? NaN) || undefined
          const maxIterations = Number(flag("--max-iterations") ?? cfg.maxIterations ?? MAX_ITERATIONS) || MAX_ITERATIONS

          state = {
            sessionID,
            directory,
            status: "running",
            phaseIdx: 0,
            phases,
            iteration: 0,
            maxIterations,
            budgetTokens,
            budgetCost,
            maxPhaseFails: cfg.maxPhaseFails ?? MAX_PHASE_FAILS,
            maxMinutes: cfg.maxMinutes ?? MAX_MINUTES,
            fails: 0,
            startedAt: Date.now(),
            updatedAt: Date.now(),
            requestDone: false,
            deferred: [],
            gateHistory: [],
          }
          await save(state)
          await syncEntry(state)
          log(state, `started in ${directory}: phases=${phases.join(",")} budget=${budgetTokens ?? "∞"}tok/$${budgetCost ?? "∞"} iters=${maxIterations}`)
          await dispatch(state, PHASE_PROMPTS[phases[0]]?.(state) ?? `${recap(state)}\n\nPHASE: ${phases[0]}. Do the work for this phase, then end your turn.`)
        },
      })
    })

    return () => controller.abort()
  },
})
