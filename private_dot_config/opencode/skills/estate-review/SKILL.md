---
name: estate-review
description: WyattAu estate portfolio review; repo health, activity, publishing status, and cross-repo dependency health
compatibility: opencode
metadata:
  audience: agents
  workflow: business
  opencode/slash: "true"
---

## What I do

Run a portfolio-level review of every repo in the WyattAu estate: which
are active, which are dormant, which have unpublished crates, which have
drifted from the engineering standards, and which have cross-repo
dependencies that need attention.

## Workflow

1. **Estate audit**; run `python3 scripts/estate-audit.py` from the
   engineering-standards repo. This checks:
   - manifest vs GitHub (does every repo in estate.yml exist?)
   - manifest vs crates.io (are published versions current?)
   - consumer pins (are exact pins still valid?)
   - dormancy (repos with no recent activity)
2. **Categorize**; group results by severity:
   - ERROR (missing repo, broken pin); fix immediately
   - DRIFT (status mismatch, version lag); fix this week
   - DEBT (technical debt flags); schedule
   - DORMANT; mark dormant or set an exemption
3. **CI health**; check the latest run status for each active repo
4. **Cross-repo dependencies**; for each repo that `lemmas_from` or
   otherwise depends on another, verify the dependency is green

## Output

A dashboard table: repo | status | last push | CI | open issues.
Then a prioritized action list (ERROR first, DRIFT second, DEBT third).

## Sources

- `estate.yml`; the manifest of record
- `scripts/estate-audit.py`; the gate that validates it
- GitHub API (via `gh` CLI); repo activity, CI status
- crates.io; published versions

## What NOT to do

- Never mark a repo as `dormant` without checking if it has consumers
  that pin it; dormancy without a consumer check breaks the audit.
- Never delete a repo without archiving it first (the code may be
  referenced by other estate docs).
