# Front-end architecture

The structure under the surface: how tokens, components, and modules are
designed so the design system survives contact with real product work.

## Tokens are the API of the design system

One module owns every token (color, type, space, radius, motion, z-index).
Components import tokens, never raw values. Consequences:

- Theme change (dark mode, client rebrand) is a token-file change.
- A component hardcoding `#fff` is a defect, not a shortcut.
- Token names describe **role**, not value: `--color-surface`, not
  `--color-white`.

## Deep modules, shallow interfaces

Ousterhout's rule, applied to components: the best component hides a large
amount of complexity behind a small contract. A component you must understand
internally to use safely is shallow — fix the interface, not the call sites.

Symptoms of shallow components:
- Prop lists mirroring internal DOM structure (`leftIconPaddingClass`).
- Call sites reaching into internals (CSS overrides per usage).
- Behavior that changes when usage order changes.

## Contract first

Before styling a component, write its contract: props (with types), events
emitted, slots/composition points, and its states — **default, hover,
focus-visible, active, disabled, loading, empty, error, overflow**. The
states are part of the contract; a button without a loading state is an
unfinished API.

## Consistent semantics across the system

Every data-bearing component uses the same error/empty/loading vocabulary.
Every destructive action confirms the same way. Every list paginates or
virtualizes the same way. Consistency is how users learn the product; each
divergence is a tax on every future screen.

## Validate at boundaries; trust internals

Parse and validate where data enters (API responses, URL params, user
input, storage). Inside the boundary, use types that make invalid states
unrepresentable rather than re-checking everywhere.

## Prefer addition over modification (Hyrum's law)

All observable behavior of a component becomes a dependency somewhere.
Changing a prop's meaning, a default, or a DOM structure breaks invisible
call sites. Add a new prop/variant; deprecate with a migration, never by
reinterpretation. Version the public surface of anything more than one team
consumes.

## CSS discipline

- One source of truth for specificity: utilities or component classes, not a
  mix that cancels itself (`.section` padding vs `.cta` margins fighting).
- Selector order and scope deliberate; no `!important` except reset wars you
  inherited and documented.
- Layout properties (grid/flex) on containers; transform/opacity for motion;
  never animate layout.

## Module boundaries

- `tokens/` → `primitives/` (Button, Input) → `patterns/` (FormField, Card)
  → `features/`. Dependencies point one direction: features may use
  patterns; patterns never import features.
- Each layer testable without the layer above it.
- A change should touch one layer; a change that always touches three is a
  boundary error.
