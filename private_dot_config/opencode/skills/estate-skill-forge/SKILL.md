---
name: estate-skill-forge
description: |
  Author, audit, and retire agent skills that actually fire and stay cheap:
  trigger-rich frontmatter, progressive disclosure, size budgets, executable
  scripts, trigger evals, deduplication against the catalog. Use when
  creating a new skill, editing an existing SKILL.md, deciding whether
  something should be a skill, command, plugin, or AGENTS.md line, or
  auditing the skill library for drift and token cost.
allowed-tools: read, grep, bash
license: Apache-2.0
---

# estate-skill-forge

A skill is a loaded instruction set, not documentation. It costs tokens
every time it fires and nothing when it does not — so it must fire on the
right prompts and pay for itself in one use.

## Choose the right carrier

| Need | Carrier |
|---|---|
| knowledge/rules applied conditionally | skill |
| a repeatable action with arguments | command |
| enforcement that must not depend on model obedience | plugin hook |
| facts needed on every turn | AGENTS.md (10 lines max) |
| deterministic computation | script called by a skill |

If it must always apply, it is not a skill. If it is >3 pages of reference,
it is a reference file behind a skill.

## Frontmatter contract

```yaml
---
name: kebab-case-unique            # ≤64 chars, matches directory
description: |
  1–2 sentences of what it does, then explicit triggers:
  "Use when …", concrete nouns, error strings, tool names, synonyms.
  End with scope limits: "Does not: …".
allowed-tools: read, grep, bash
license: Apache-2.0
---
```

The description is the retrieval key. Name the *situations*, not the
philosophy: "use when a Docker build fails on a missing system lib" beats
"use for container work".

## Size budgets

| Part | Target | Hard limit |
|---|---|---|
| SKILL.md | 400–900 words | 2,000 words |
| description | 200–400 chars | 500 chars |
| references/ | one topic per file | loaded selectively |
| scripts/ | deterministic, `--help`, exit codes | no prose |

Over budget → move depth into `references/<topic>.md` and keep SKILL.md a
router with a "read this when" table.

## Writing rules

1. **Rules must be checkable.** "Be careful" is noise; "cap output at 40
   lines" is a rule.
2. **Decision table over prose** for enumerable choices.
3. **Anti-patterns section** — the mistakes the model actually makes.
4. **One canonical term** per concept; no synonyms for the same step.
5. **No restating the system prompt.** Skills add, they do not repeat.
6. **Examples are short and real**: command in, decisive output out.
7. **Progressive disclosure**: SKILL.md answers "should I load more, and
   which file?" — never dump every detail at load time.

## Eval before shipping

Write five prompts that must trigger the skill and three that must not
(near-misses from sibling skills). Run them; if the model does not invoke
the skill on 4/5 positives, rewrite the description, not the body.

```bash
python3 scripts/skill_audit.py ~/.config/opencode/skills   # structure + cost
```

## Deduplication

Before adding: `grep -ril "<topic>" ~/.config/opencode/skills`. Two skills
covering one topic is a retrieval bug — merge, or give each a distinct
trigger and cross-reference. Keep a router skill only when siblings exceed
five.

## Retirement

A skill that has not fired in a month, or whose canon changed, is drift.
Delete or update it in the same commit that changed the canon. Projected
skills (standards-dist) are refreshed by rebuild, never hand-edited.

## Anti-patterns

- Vague descriptions that never match a real prompt.
- 3,000-word SKILL.md that duplicates a reference doc.
- Skills that restate AGENTS.md.
- Two skills with overlapping triggers.
- Hand-editing a projected skill.
