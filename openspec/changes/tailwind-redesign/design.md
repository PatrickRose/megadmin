## Context

The app renders 45 HAML views with ~318 Bootstrap-class usages, a custom apricot
SCSS palette duplicated across several files, Bootstrap Icons, and three
hand-rolled popup scripts. The Pennine Megagames design system defines the target
components as React JSX — structural references, not droppable into HAML. The
design tokens and Tailwind theme are provided by the design-tokens change.

## Goals / Non-Goals

**Goals:**
- Re-skin to the design system, component-by-component, staying shippable
  throughout (Bootstrap and Tailwind coexist until the final removal).
- Encapsulate components as tested ViewComponents mapping 1:1 to the design system.

**Non-Goals:**
- Functional/behavioural changes to the app.
- Keeping Bootstrap Icons (replaced by Font Awesome Free).

## Decisions

- **ViewComponent per design-system component.** Each becomes a tested Ruby
  component (Button, Icon, Card, Alert, DataTable, FormBox/FormField, Modal),
  authored from the JSX references — not copied.
- **Chrome first, then components, heaviest views first.** Rebuilding the layout
  flips the whole app to the new look early and shakes out the token wiring;
  `events/show`, `event_signups/index`, `events/index` follow as the highest-value
  ports.
- **Stimulus for the dropdown and modals.** Removing Bootstrap JS forces a
  replacement; the one dropdown and the three hand-rolled popups become Stimulus
  controllers.
- **Bootstrap removed last.** Its CSS stays vendored until no view references it,
  keeping every intermediate commit green.

## Risks / Trade-offs

- **Visual regressions across many views** → a Playwright pass over key screens in
  light and dark before the final Bootstrap removal.
- **JSX components are references, not code** → ViewComponents are hand-authored
  from the design-system spec, verified against the specimen cards.
- **Divergence from the design system on icons** → the design system specifies
  Bootstrap Icons; using Font Awesome is a deliberate, documented divergence
  localised to the Icon component.

## Migration Plan

1. ViewComponent harness → chrome + dropdown.
2. Core components (Icon/Button/Card/Alert/Modal) and view ports (DataTable,
   forms), heaviest views first.
3. Remaining views.
4. Remove Bootstrap; final rubocop + rspec + Playwright pass.

## Open Questions

- Whether to keep any Bootstrap grid utilities transitionally or replace all
  layout with Tailwind from the first ported view.
