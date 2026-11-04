Audit the OpenCode skill library: structure, triggers, size budget, duplication, token cost.

Arguments (optional): a path to audit. Default: ~/.config/opencode/skills

Run:

```bash
python3 ~/.config/opencode/scripts/skill_audit.py ${ARGUMENTS:-~/.config/opencode/skills}
```

Then act on the findings, in this order:

1. **ERROR** → fix now: missing frontmatter, name/directory mismatch, duplicate
   name, over word budget (default 2,000).
2. **Short description / no triggers** → rewrite the `description` as
   "what it does + Use when <concrete situations> + Does not: <scope>".
   The description is the retrieval key; a skill that never fires is dead weight.
3. **Long skill without references/** → move depth into `references/<topic>.md`
   and leave a "read this when" table in SKILL.md.
4. **Near-duplicates** → merge, or give each a distinct trigger and
   cross-reference.

Rules:
- Projected skills (PROVENANCE.yml) are never hand-edited; refresh via
  standards-dist build.
- After edits, re-run the audit and confirm zero ERROR.
- Report: skill count, total load cost, and the delta before/after.
