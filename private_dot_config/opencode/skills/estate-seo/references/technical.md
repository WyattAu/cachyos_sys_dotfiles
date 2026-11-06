# Technical SEO — audit checklist and crawler facts

Order matters: crawl → index → render → rank. Fix in that order.

## Crawlability

- robots.txt exists, valid, not blocking CSS/JS needed for rendering.
- XML sitemap: submitted, canonical URLs only, <50k URLs / <50MB per file.
- Important pages within 3 clicks of the homepage; no orphan pages.
- No accidental `noindex` (check rendered DOM, not just source — JS can
  inject it).
- Large sites (>10k pages): watch crawl stats; 5xx/slow responses back off
  the crawler automatically — there is no manual crawl-rate control
  (removed 2024). Influence crawling via sitemaps and server speed.

## The 2MB cap

Googlebot fetches the first **2MB of HTML** (uncompressed). Inline
base64 images, oversized CSS/JS, or bloated navigation can push critical
content and JSON-LD past the cap — out of the index silently. Keep key
content and structured data early in the document.

## Rendering

If critical content requires JS: ensure it renders in the DOM without
interaction, keep the JS bundle lean, and prefer server-side rendering for
indexable pages. Verify with a rendered-DOM fetch, not view-source.

## AI-crawler policy (decide and record)

| Crawler | Blocking it affects | Not affected |
|---|---|---|
| Google-Extended | Gemini training/grounding | Search indexing, AI Overviews |
| GPTBot | OpenAI training | ChatGPT Search |
| ClaudeBot | Anthropic training | Search indexing |
| Applebot-Extended | Apple Intelligence | Apple search |

Blocking training crawlers does not remove you from answer engines. Policy
is a product decision: allow all (maximum visibility), block training only,
or block all — record it in robots.txt comments and the repo README.

## Schema (JSON-LD)

- JSON-LD is the primary format (Google's stated preference).
- Sitewide: `Organization` (with logo, sameAs). Per page type: `Article`
  (with author, dates), `Product` (offers, ratings — only if real),
  `FAQPage` (only for real visible FAQs), `HowTo`, `BreadcrumbList`.
- Validate before ship (Rich Results Test or schema validator); never
  mark up content not visible on the page.
- Keep JSON-LD inside the first 2MB.

## International

`hreflang` pairs (including x-default) only when genuine language/region
variants exist; each URL self-references; return 200s, not redirects.

## Core Web Vitals (p75 field data)

LCP <2.5s (hero image preload, no render-blocking chains), INP <200ms
(break long tasks), CLS <0.1 (reserve media dimensions). Measure field
data (real users), not lab alone.
