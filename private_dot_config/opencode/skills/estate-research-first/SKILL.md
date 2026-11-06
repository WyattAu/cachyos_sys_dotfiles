# Estate Research First

---
name: estate-research-first
description: |
  Ground design and debugging decisions in primary sources: tiered source
  quality, one-concept-per-query retrieval, citation format, and the rule
  that a decision needs either a source or a measurement. Use when choosing
  an architecture, evaluating a library or protocol, debugging behaviour
  that training data may predate, writing a design doc or yellow paper, or
  when the user asks for research, best practice, or the latest approach.
allowed-tools: read, grep, bash, webfetch, websearch
license: Apache-2.0
---

# estate-research-first

Training priors go stale; measurements and primary docs do not. Every
non-trivial design decision needs a source or a measurement, cited.

## Source tiers

| Tier | Sources | Use |
|---|---|---|
| 1 | spec, RFC, upstream source, paper, official docs (current version) | decides |
| 2 | vendor engineering blog, maintainer issue/PR, release notes | supports |
| 3 | tutorials, Stack Overflow, model memory | hints only |

Tier-3 claims may start a search, never end one. Version-check anything
from memory: the API you remember may be two majors behind.

## Retrieval protocol

1. **One concept per query.** "How to configure X in vN"; not "X, Y, Z
   and best practices".
2. **Resolve the source first** (library ID, RFC number, repo path), then
   query the specific concept.
3. **Prefer code in the wild** to invent syntax: search real usage in
   maintained repos.
4. **Read the decisive section only.** Fetch with a length cap or grep the
   page; do not ingest whole docs sites.
5. **Record what you read**: URL, version/date, section. An uncited claim
   is an assumption and must be labelled as one.

## Decision record

```
decision:  <what we will do>
because:   <tier-1 source or measurement>
rejected:  <alternative>; <why>
revisit:   <trigger: new version, benchmark, failure>
```

Design docs and yellow papers carry this block per non-obvious choice.
Preferences ("we like X") are allowed but named as preferences.

## Research before building

- New dependency: check licence, maintenance, last release, open CVEs,
  binary size, and whether the estate already has a crate for it.
- New protocol: read the spec section on failure modes before the happy
  path.
- Perf claim: measure the baseline first, then the change, same machine
  and method.
- Bug in a dependency: read the upstream source and issues before
  working around.

## Anti-patterns

- "Best practice" with no source and no version.
- Benchmarking against a strawman or a different machine.
- Citing a blog that cites the spec instead of the spec.
- Adopting a library because it is popular (stars are not fitness).
- Research that never ends: timebox to the decision it unblocks.
