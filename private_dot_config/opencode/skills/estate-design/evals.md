# estate-design — trigger evals

Per estate-skill-forge: five prompts that MUST trigger the skill, three
near-miss prompts that MUST NOT, and the expected behavior contract.
Re-run after any description change; 4/5 positives required to ship.

## MUST trigger (expect estate-design load)

1. "Build a landing page for our backup tool; the current one looks
   AI-generated."
   → triggers on: build UI + "looks AI-generated" (genericness tell).
2. "Redesign the settings screen of the desktop app — it's a wall of
   cards."
   → triggers on: redesign + app screen (the card-kit tell).
3. "Which typeface pair and type scale should the docs site use?"
   → triggers on: typography choice.
4. "Review this component's props API — every usage needs to reach into
   its DOM."
   → triggers on: component API structure (shallow-module symptom).
5. "Add a dark theme to the design system."
   → triggers on: design-system + theme change (token-file change rule).

## MUST NOT trigger (expect no estate-design load)

1. "Fix the flaky integration test in CI." → debugging, not design.
2. "Design a logo for the estate." → explicitly out of scope (brand-mark).
3. "Refactor the sqlite layer to use rusqlite transactions." → backend
   architecture, no UI surface.

## Behavior contract when loaded

- Three directions BEFORE building; the genericness review happens on the
  plan, not after the code.
- The floor's ten rules are cited as checkable, not as vibes.
- Screenshot pass at 1440/1024/768/390 before declaring done.
- References read selectively: floor.md when implementing, page-kinds.md
  when structuring a new page, copy.md when writing text, architecture.md
  when touching module boundaries.
