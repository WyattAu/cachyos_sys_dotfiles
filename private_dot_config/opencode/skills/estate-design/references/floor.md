# The floor — full rule list with fixes

Non-waivable rules distilled from Hallmark's floor, tasteskill's house
rules, and Anthropic's frontend-design guidance. Each is checkable in code
or in a screenshot.

## Tokens

```css
:root {
  --color-base: #…; --color-surface: #…; --color-ink: #…;
  --color-accent: #…; --color-accent-2: #…;
  --font-display: …; --font-body: …; --font-mono: …;
  --space-1: …; --radius-*: …;
}
```

No literal color or `font-family` anywhere past the token block. Theme
switching = swapping the token block, nothing else.

## Overflow and layout

```css
html, body { overflow-x: clip; }   /* never hidden; never width: 100vw */
.grid-images { grid-template-columns: repeat(3, minmax(0, 1fr)); }
h1, h2, h3 { overflow-wrap: break-word; min-width: 0; }
```

## Motion

```css
/* Never transition: all. Never animate layout properties
   (width, height, top, left). Transform and opacity only. */
.card { transition: transform 160ms ease, box-shadow 160ms ease; }
.card:hover { transform: translateY(-2px); }
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation: none !important; transition: none !important; }
}
```

Micro-interaction set (apply once, everywhere, via one layer): linked cards
lift 2px; photos zoom 1.02–1.03 inside their frame; buttons step on hover
and press on click; link underlines draw. No tilt, no carousels, no timed
tabs.

## Focus and semantics

- Every interactive element: instant `:focus-visible` style (never
  `outline: none` without a replacement).
- Landmarks and headings in order; buttons are `<button>`, links are `<a>`;
  icon-only controls carry `aria-label`.
- Content visible with scripting off (no JS-gated first paint).

## Prohibitions (the tells)

- Purple-to-blue gradient; card inside a card; emoji as an icon; hand-drawn
  browser/OS window mockups; decorative status dots.
- Eyebrow labels; tracked capitals or small caps for labels; middle-dot
  meta strings ("A · B · C"); `WORD — fragment` labels; arrows glued to
  link text ("Read more →").
- One italic/bold word inside a roman heading.
- Invented metrics, testimonials, client counts, logo walls.
- Captions under images; licence credits outside a single footer line.
- Numbered markers (01/02/03) on content that is not a sequence.
- Tinted near-black (#0B0B0B, #111) standing in for black; monospace for
  small data labels unless data is genuinely tabular.

## Screenshot pass

At 1440, 1024, 768, 390: does every visual render? Does any section heading
peek in from the next screen? Are edges equal? Does any prohibition appear?
Remove one element before finishing.
