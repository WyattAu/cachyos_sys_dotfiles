# GEO/AEO — being cited by AI engines

Generative Engine Optimization: when someone asks an AI engine a question
in your domain, your page is the quoted source.

## Citability rubric (score 0–100)

| Category | Weight | What scores |
|---|---|---|
| Answer-block quality | 30% | answer in sentence one; definition patterns ("X is …"); quantified answers ("$Y at p75"); explicit comparisons ("differs in three ways: …") |
| Passage self-containment | 25% | any paragraph extracted alone still makes sense; no dangling pronouns into other sections |
| Structural readability | 20% | strict H1>H2>H3; question-based headings; 2–4 sentence paragraphs; tables for 3+-item comparisons |
| Uniqueness/authority signals | 15% | original data, dates, named methods, author credentials |
| Freshness | 10% | visible dates; update history; stale stats marked stale |

Audit a target page against the rubric, fix the lowest category first.

## llms.txt

Root-level curated map for AI engines (the estate's SPEC-CORE SC-10
artifact — one pipeline serves both docs and SEO):

```
# Site Name
> One-paragraph summary of what the site is.

## Docs
- [Page title](url): one-line description
```

Keep it current in the docs pipeline; a stale llms.txt misleads engines
about the site's structure.

## Citability patterns

- Definitions: "X is [definition]." as a standalone sentence.
- Quantities with units, dates, and measurement method.
- Direct comparisons as tables or explicit enumerations.
- FAQ sections only for questions users actually ask; answers 40–60 words,
  self-contained.
- Author entity: named, credentialed, linked (same person across pages) —
  engines weight source consistency.

## Measurement

Monthly citation check: ask each major engine your target queries in a
fresh session; record cited/not and which competitor was cited instead.
Trend it. Citation share is the GEO KPI; traffic from AI referrals is the
secondary signal.
