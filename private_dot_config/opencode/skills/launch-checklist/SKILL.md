---
name: launch-checklist
description: Product launch readiness — technical, marketing, and operational gates before shipping
compatibility: opencode
metadata:
  audience: agents
  workflow: marketing
  opencode/slash: "true"
---

## What I do

Run the pre-launch checklist across three layers: technical readiness,
marketing collateral, and operational stability. Each gate must pass
before the next is checked — a product that works but has no docs is
not ready, and neither is a product with great docs that crashes.

## Gates (in order)

### Gate 1: Technical
- [ ] Tests pass (`lake build` / `cargo test` / `pytest` / project gate)
- [ ] No known HIGH/CRITICAL CVEs (trivy scan)
- [ ] CHANGELOG updated
- [ ] Version bumped (semver; check for breaking changes)
- [ ] Secrets scanned (gitleaks — no keys in the repo)
- [ ] README reflects the current feature set

### Gate 2: Documentation
- [ ] Installation instructions verified on a clean environment
- [ ] First-run experience documented (what does the user see?)
- [ ] Known limitations documented (what does it NOT do?)
- [ ] Architecture overview for contributors

### Gate 3: Operational
- [ ] CI pipeline green (all jobs, not just the ones you ran locally)
- [ ] Error handling: what does the user see when it fails?
- [ ] Telemetry/logging: can you debug a user report without their machine?
- [ ] Rollback: can you revert to the previous version safely?

### Gate 4: Marketing
- [ ] Launch announcement drafted (HN, Reddit, Twitter — different tones)
- [ ] Demo GIF or screenshot that shows the value in <10 seconds
- [ ] Comparison with the nearest alternative (honest, not defensive)
- [ ] License confirmed (MIT / Apache-2.0 / etc)

## What NOT to do

- Never launch on a Friday (no one is around to handle issues).
- Never launch without testing the INSTALL command on a clean machine.
- Never launch with a known security issue "because it's minor" —
  it will be the first thing someone finds.
