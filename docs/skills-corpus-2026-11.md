# Agent-skill corpus analysis → estate skill pack

status: CURRENT
method: shallow clone of 13 public skill repositories (2026-11-04), stdlib
scanner over every `SKILL.md` (`skill_scan.py`, ~40 MB of markdown)

## Corpus

| Metric | Value |
|---|---|
| repositories cloned | 13 |
| `SKILL.md` files found | 10,444 |
| unique after content-hash dedupe | 4,539 |
| total bytes (unique) | 40.9 MB |
| median skill length | 984 words |
| mean skill length | 1,154 words |
| descriptions with explicit trigger phrasing | 31–100% (repo-dependent) |
| skills shipping `references/` | 22% |
| skills shipping `scripts/` | 8% |

Repos sampled: `anthropics/skills`, `anthropics/claude-plugins-official`,
`mattpocock/skills`, `addyosmani/agent-skills`, `obra/superpowers`,
`affaan-m/ECC`, `mksglu/context-mode`, `OthmanAdi/planning-with-files`,
`JuliusBrussee/caveman`, `NVIDIA/SkillSpector`,
`VoltAgent/awesome-agent-skills`, `sickn33/agentic-awesome-skills`,
`K-Dense-AI/scientific-agent-skills`, `vercel-labs/skills`.

## Measured signals

1. **Trigger phrasing separates curated from bulk corpora.** Curated repos
   put "Use when …" triggers in 70–100% of descriptions (addyosmani 96%,
   obra 100%, caveman 75%, anthropics 70%); the 8,974-skill bulk dump is at
   31%, ECC at 46%. A skill without triggers is not retrieved.
2. **Brevity correlates with the skills people actually cite.**
   context-mode's core skill is 159 words, caveman's 371, SkillSpector's
   index cards 48; the corpus median is 984. The lean skills are rules, the
   median skills are documentation.
3. **Progressive disclosure is rare but load-bearing.** Only 22% ship
   `references/`, yet every >2,000-word skill in the corpus that stays
   usable routes depth through references and keeps `SKILL.md` as a router.
4. **Determinism is delegated to scripts.** The skills that produce
   repeatable output (SkillSpector, vercel-labs/skills, scientific skills)
   ship `scripts/` instead of describing the computation in prose.
5. **Enforcement lives in hooks, not instructions.** context-mode and
   proof-loop both work because a harness hook runs the rule (tool routing,
   gates, budget checks). Prose rules alone decay over long sessions.
6. **Persistence beats recall.** planning-with-files exists entirely to
   re-inject a crash-proof plan after `/clear` and compaction; superpowers'
   `executing-plans` adds a completion contract per task.

## Adopted into the estate pack

| Skill | Source pattern | Estate form |
|---|---|---|
| `estate-context-economy` | context-mode, caveman | budget table, locate-before-read, output caps, delegation |
| `estate-rigor-loop` | diagnosing-bugs, superpowers, addyosmani | falsifiable claim → cheapest test → evidence block → ladder |
| `estate-skill-forge` | skill-creator, SkillSpector | carrier table, frontmatter contract, size budget, trigger evals |
| `estate-plan-ledger` | planning-with-files | append-only ledger, status table, bounded resume |
| `estate-orchestrate` | dispatching-parallel-agents, cavecrew | delegation decision table, task/return contract |
| `estate-research-first` | mcp-builder research phase, our SPEC-CORE | source tiers, one-concept queries, decision record |

Tooling added with the pack:

- `scripts/skill_audit.py` — frontmatter, triggers, size budget, duplication,
  estimated load cost. Exit 1 on errors.
- `scripts/context_report.py` — session token totals, per-tool output bytes,
  largest calls, cache-hit ratio (read-only over the session DB).
- commands `/skill-audit` and `/context-report`.

Always-on: a 14-line Context discipline block in
`~/.config/opencode/AGENTS.md` (the skills are conditional; this is the
floor).

## Rejected

- **Bulk importing thousands of skills.** 8,974 skills at a 31% trigger
  rate is retrieval noise, and every loaded skill costs 300–900 tokens.
  The estate keeps a curated set with audited triggers.
- **Marketing-copy descriptions.** They read well and never fire.
- **Harness-locked hooks.** Rules stay in portable markdown; hooks are a
  separate, optional layer (OpenCode plugin) with estate fallbacks.
- **Compression that touches payload.** Caveman's own rule — code, paths,
  commands, numbers stay verbatim — is adopted; its voice is not imposed.

## Audit baseline (2026-11-04, after pack)

24 skills installed, ~13.1k tokens if all were loaded, largest 927;
zero errors under `skill_audit.py`.

## Provenance

Clones and scanner output: `/home/wyatt/skills-research/`
(`clones/`, `catalog.jsonl`, `skill_scan.py`). Re-run:

```bash
python3 skills-research/skill_scan.py skills-research/clones --out catalog.jsonl
python3 ~/.config/opencode/scripts/skill_audit.py ~/.config/opencode/skills
```
