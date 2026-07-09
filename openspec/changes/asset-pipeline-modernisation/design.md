## Context

Shakapacker is the sole pipeline (no Sprockets/Propshaft), building both JS (SWC)
and CSS (Sass) into `public/packs`. Bootstrap JS is barely used (one dropdown; the
modals are hand-rolled). Trix/Action Text is the only substantial JS dependency.
The Docker `build` stage runs `assets:precompile` via webpack; the runtime image
also ships Node because Grover drives Puppeteer to render PDFs.

## Goals / Non-Goals

**Goals:**
- Match the modern Rails default stack (Propshaft + importmap + Hotwire) and host
  Tailwind via tailwindcss-rails.
- Keep the app shippable throughout — Bootstrap CSS stays until the redesign
  removes it.

**Non-Goals:**
- Visual redesign (that is the separate design-tokens + tailwind-redesign work).
- Removing Node from the runtime image (PDF generation needs it).

## Decisions

- **importmap over jsbundling.** The JS surface is tiny (Turbo, Stimulus, Trix).
  importmap needs no Node build; jsbundling (esbuild) is the escape hatch only if
  a dependency proves painful on importmap.
- **tailwindcss-rails, not Tailwind-in-webpack.** With Shakapacker removed,
  tailwindcss-rails (standalone binary, no Node) is the idiomatic modern-Rails
  choice; it composes with Propshaft. Tailwind v4's CSS-first `@theme` is what the
  design-tokens change wires up.
- **Node stays at runtime.** The build-time Node/Yarn can be slimmed, but the
  production image must retain Node for Grover/Puppeteer — a subtle trap (the
  image would build fine and then fail to render PDFs).
- **Coexistence.** Bootstrap CSS remains vendored through the migration so the app
  renders; Bootstrap JS + `@rails/ujs` are replaced by Turbo/Stimulus here.

## Risks / Trade-offs

- **PDF rendering breaks if Node is dropped** → validated by a staging deploy that
  renders a real PDF before production.
- **Trix/Action Text on importmap** → officially supported; re-run
  `action_text:install`. If problematic, fall back to jsbundling.
- **Lockfile/CI churn while package.json is removed** → sequence the removal after
  importmap is proven so CI never sees a half-migrated state.

## Migration Plan

1. Add the new stack alongside Shakapacker; migrate JS to importmap.
2. Re-pin Trix/Action Text; add tailwindcss-rails (unthemed).
3. Rework the Dockerfile; prove build + `/up` + PDF on staging.
4. Remove Shakapacker/webpack and the app package.json.
Each step deploys to staging first; rollback is redeploying the prior image.

## Open Questions

- Whether any small dev-only tooling (e.g. the OpenSpec CLI) warrants keeping a
  minimal `package.json`, or is better invoked via pinned `npx`.
