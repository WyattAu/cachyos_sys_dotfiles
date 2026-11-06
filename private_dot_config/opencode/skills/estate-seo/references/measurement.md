# Measurement — fixed cadence, readable causality

## Sources

| Signal | Source | Cadence |
|---|---|---|
| queries, impressions, CTR, coverage | Search Console | weekly |
| Core Web Vitals field data (p75) | CrUX / Search Console | monthly |
| organic sessions, conversions | server logs / privacy-first analytics | weekly |
| AI citations per target query | direct engine asks, fresh session | monthly |
| referring domains, brand mentions | link index + mention search | monthly |
| rank positions for cluster heads | a rank tracker or manual p1–p10 check | weekly |

## Rules

1. **Same method every time.** A metric whose method changes is a new
   metric; note the method in every report.
2. **Annotate before you measure outcomes**: every ship that could move
   rankings (content, schema, robots policy, CWV work) gets a dated entry
   in the report, so deltas have candidate causes.
3. **Report deltas with dates**: "+3 positions on cluster X since the
   schema ship on <date>" — not absolute numbers without baselines.
4. **Both KPI families**: classic (positions, sessions, conversions) and
   AI-era (citation share, AI-referral sessions). Ranking without citations
   is half the picture in 2026.
5. **Distinguish volatility from movement**: one-week swings are noise;
   judge on 4-week windows unless the change was major (site migration,
   robots policy change).

## Report shape (monthly, one page)

- Deltas table: metric | last | now | delta | candidate cause
- Citations: query → cited us? → cited instead?
- Work shipped this month (dated)
- Next month's plan (ranked by expected impact)
