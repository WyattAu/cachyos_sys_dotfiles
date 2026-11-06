---
name: estate-seo
description: |
  Combined SEO + GEO/AEO doctrine: technical SEO, content/E-E-A-T,
  AI-engine visibility (llms.txt, citability, crawler policy), authority,
  measurement. Use when auditing, building, or improving any site's
  search or AI-engine visibility; when writing titles, metas, headings,
  or JSON-LD; when asked about rankings, indexing, llms.txt, AI crawlers,
  schema, or content briefs; when a page "isn't ranking" or "isn't cited
  by AI engines". Not for paid search or black-hat tactics.
allowed-tools: read, grep, glob, bash, webfetch
license: Apache-2.0
---

# estate-seo

Search and AI-engine visibility is one discipline in 2026: the same crawl,
the same content, three audiences (Google, AI training crawlers, AI answer
engines). Optimize all three deliberately — never by accident.

## The four pillars

| Pillar | Question it answers | Core artifacts |
|---|---|---|
| Technical | can engines crawl and index it? | robots.txt, sitemap, CWV, JSON-LD |
| Content | does it answer intent better than rivals? | briefs, answer-first copy, E-E-A-T |
| GEO/AEO | do AI engines cite it? | llms.txt, citability, crawler policy |
| Authority | do independent sources vouch for it? | backlinks, brand mentions |

Diagnose in pillar order: technical failures mask everything downstream.

## Process

1. **Audit** before changing: crawl status, index coverage, CWV field data,
   current rankings, AI-engine citations (ask the engines directly).
2. **Cluster keywords by intent** (informational / comparative /
   transactional / navigational); one page per cluster, one intent per page.
3. **Brief before writing**: target query, intent, answer in one sentence,
   section outline, entities to cover, internal links in/out.
4. **Implement** against the floor (below), then measure at fixed cadence.

## The floor (checkable)

1. One `<h1>` per page matching the primary intent; H2/H3 hierarchy never
   skips levels; question-based H2s where they match real queries.
2. Title ≤60 chars, meta description ≤155, both unique per page, primary
   intent phrase present naturally.
3. JSON-LD (Schema.org) on every indexable page: `Organization` sitewide;
   `Article`/`Product`/`FAQPage`/`HowTo` per type. Validate before ship.
4. `llms.txt` at the root listing canonical docs; AI-crawler policy in
   robots.txt is a **decision**, recorded (allow all / block training only
   / block all — each has product consequences).
5. Core Web Vitals within budget: LCP <2.5s, INP <200ms, CLS <0.1 at p75.
6. Canonical on every page; no duplicate indexable URLs; important pages
   within 3 clicks of the homepage; critical content and JSON-LD inside
   the first 2MB of HTML.
7. Every image has descriptive alt text; no text baked into images.
8. Never cloak, never spin, never invent facts for rankings.

## GEO/AEO — being the cited source

AI engines cite pages that are **self-contained, quantified, and
structurally parseable**:

- **Answer-first paragraphs**: the answer in sentence one ("X is …", "The
  average cost of X is $Y"), support after. No wind-ups.
- **Passage self-containment**: any paragraph must make sense extracted
  alone — AI quotes passages, not pages.
- **Comparison tables** for any 3+-item comparison; tables extract with
  high fidelity.
- **Question-based headings** match query forms directly.
- **Definitions and numbers over vague prose** — "many factors affect" is
  uncitable; "$Y at p75, measured on <date>" is citable.
- `llms.txt` gives engines a curated map; keep it current (the estate's
  SPEC-CORE SC-10 projection is this exact artifact — docs and SEO share
  one pipeline).

## Content and E-E-A-T

Real experience beats volume: named authors with credentials, first-hand
detail ("measured on <date> with <method>"), original data, dated content
with visible update history. One intent per page; depth beats thin
coverage; internal links use descriptive anchors from related pages.

## Authority

Backlinks and brand mentions follow from being citable and useful: publish
original data/methods, fix the citations you deserve (unlinked mentions),
never buy links. Track referring domains and brand-mention frequency as
the authority KPI.

## Measurement

Fixed cadence, same method every time: Search Console (queries, coverage,
CWV field data) + server/analytics (organic sessions, conversions) + a
monthly AI-citation check (ask each major engine the target queries;
record cited/not). Report deltas, not absolute noise; annotate changes
with dates so causality is readable.

## Anti-patterns

- Keyword stuffing; writing for engines before users.
- one-page-one-intent violated (cannibalization).
- Schema that describes content the page does not contain.
- Blocking AI crawlers "for safety" without recording the decision.
- Chasing rankings without measuring citations — the 2026 half-metric.
- Shipping llms.txt once and letting it rot.
