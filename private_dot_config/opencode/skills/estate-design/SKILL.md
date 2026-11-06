---
name: estate-design
description: |
  Combined UI/UX/visual/architecture design doctrine: landing pages,
  dashboards, app screens, design systems, and their module boundaries.
  Use when building, designing, redesigning, restyling, polishing, or
  reviewing any UI, web page, screen, component, or design system; when a
  page "looks generic, templated, or AI-made"; when choosing typography,
  color, spacing, or motion; when structuring frontend modules or component
  APIs. Does not cover print/3D art direction or brand-mark design.
allowed-tools: read, grep, glob, bash
license: Apache-2.0
---

# estate-design

Produce work a studio would ship: grounded in the subject, decided on
purpose, and indistinguishable from human craft. The two failure modes are
templated defaults (the model's trained aesthetic) and unstructured
cleverness. This skill is the guardrail for both.

## Process (do not skip steps)

1. **Identify the subject** before designing: what it is, who it is for, its
   one primary job. Distinctive choices grow out of the subject's world —
   industry, materials, vernacular; never out of your default taste.
2. **Deal three directions**, even when the brief names a style: three
   one-paragraph directions (mood, type stance, color stance, layout
   concept), each with one sentence on what it costs. The user picks; the
   brief's own words then always win.
3. **Write the token plan** for the chosen direction:
   - Color: 4–6 named hex values (base, surface, ink, accent, accent-2).
   - Type: one or two families with roles (display/body/mono), a type scale,
     body line-length under ~80 characters.
   - Layout: alignment decision + one ASCII wireframe per screen.
   - Principles: one sentence each on what makes *this* page this page.
4. **Genericness review** before building: for each plan element ask "would
   I produce this for any similar brief?" If yes, spend that freedom
   differently. The known default cluster: warm cream + high-contrast serif
   + terracotta accent; near-black + single acid accent; broadsheet hairlines
   with zero radius; identical rounded cards with one shadow; tracked ALL-
   CAPS eyebrows; middle-dot meta strings; `WORD; fragment` labels; tinted
   near-black standing in for black; arrows glued to links. Legitimate for
   some briefs; a choice, never a default.
5. **Build, then critique in a real browser**: screenshot at 1440, 1024, 768,
   390; check the floor checklist (below) at each width; remove one thing
   before finishing.

## The floor (non-waivable, checkable)

1. Every color and font family flows through a token declared at `:root` (or
   the theme block). No literal color or `font-family` past the token block.
2. Every interactive element has `:focus-visible`, appearing instantly.
3. Every animation has a `prefers-reduced-motion: reduce` fallback; content
   is visible with scripting off.
4. Never `transition: all`; never animate `width`, `height`, `top`, `left`.
5. `overflow-x: clip` on `html` and `body`; never `hidden`; never `100vw`.
6. Image-bearing grid tracks use `minmax(0, 1fr)`; headings carry
   `overflow-wrap: break-word; min-width: 0`.
7. Every visual renders at all four widths; no empty ground, no caption
   under images (credits go in one footer line).
8. One section per screen at 1440×900; equal left/right content edges.
9. Every interactive element gets the hover/press layer (lift 2px, image
   zoom 1.02–1.03, press state, underline draw); via the motion layer,
   once, consistently.
10. Accessibility is the floor, not a feature: contrast, focus, reduced
    motion, keyboard paths, semantics.

## Page kind decides everything

Declare the kind (`<html data-type>` + `<meta name="site-kind">`) and let it
drive structure and effects:

| Kind | Examples | Design consequence |
|---|---|---|
| software | SaaS, AI, dev tools | effects, scenes, dark heroes allowed |
| gaming / tech | games, hardware | shader/scene moments allowed |
| product | physical goods sold online | real product renders + photos |
| service | clinics, studios, agencies | proof of people, photography |
| place | cafes, shops, hotels | 12–20 real photos, no effect layer |

Effects and creative moments belong to tech kinds only. A bakery gets
photographs, flat color, and type; never shaders. Derive the page's primary
verb (try, buy, book, visit, hire, sign up, join) and let it order the
sections.

## Typography, color, motion; the decided defaults

- One or two type families, clearly distinct roles; set a deliberate type
  scale; headings are type treatments, not neutral delivery.
- Structural devices (outlines, numbers, dividers, labels) encode
  information. Numbered markers only when the content is actually a
  sequence.
- One orchestrated moment per page (a load sequence or one reveal); motion
  that *answers a user action* is always welcome; per-card fade-up entrances
  are the generic default; don't.
- Spend boldness in one place: one memorable element, everything else quiet.

## Copy is design content

Write from the user's perspective ("notifications", not "webhook config");
active voice; CTAs say what happens ("Save changes", not "Submit"); an
action keeps its name through the whole flow (Publish → Published); errors
explain what happened and how to fix it without apologizing; empty states
invite action. No invented metrics, testimonials, or customer counts; ever.

## Front-end architecture (the parts users never see)

- **Tokens are the API of the design system**: one module owns them; nothing
  imports raw values. Changing the theme is a token-file change.
- **Deep modules, shallow interfaces** (Ousterhout): a component hides its
  complexity behind a small prop/contract surface; a component that requires
  knowing its internals to use is shallow; redesign it.
- **Contract first**: define the component's props/events/slots (its API)
  before styling it; consistent error/empty/loading semantics across every
  data-bearing component; validate at boundaries (inputs, API responses),
  trust internals.
- **Prefer addition over modification** (Hyrum's law): new variant props beat
  changed prop meanings; every existing call site keeps its behavior.
- CSS specificity: avoid class/element selectors that cancel each other
  (`.section` padding vs `.cta` margins); order and scope styles deliberately.

## Anti-patterns

- Starting from your default aesthetic instead of the subject's world.
- One direction instead of three; building before the genericness review.
- Card-in-card, purple-blue gradients, emoji as icons, hand-drawn browser
  chrome, decorative status dots, `01/02/03` on non-sequences.
- Invented social proof; lorem ipsum shipped as final copy.
- Effects on a place/service page; per-card entrance animations.
- Shipping without the four-width screenshot pass.
