## Why

The app is built on Shakapacker (webpack + SWC + Sass) — an aging, heavyweight
toolchain. To make it equivalent to a modern Rails application and to host a
Tailwind redesign cleanly, the front end should move to the modern Rails default
stack. This is the load-bearing, riskiest part of the modernisation, so it is
validated on staging before it reaches production.

## What Changes

- **BREAKING** (build only): replace Shakapacker/webpack with the modern Rails
  default stack — **Propshaft** (static assets), **importmap-rails** (JS, no
  bundler), **tailwindcss-rails** (CSS), and **Hotwire** (Turbo + Stimulus).
- Replace `@rails/ujs` with Turbo; port `data-confirm`/`data-method` behaviour.
- Re-pin **Trix / Action Text** on importmap.
- Add **tailwindcss-rails** (Tailwind v4 standalone binary) building through
  Propshaft; run the watcher via `bin/dev`.
- Rework the Dockerfile asset build for the new pipeline; **keep Node in the
  runtime image** (Grover/Puppeteer renders PDFs).
- Remove Shakapacker, webpack, SWC, sass-loader, their config, and the `webpack`
  docker-compose service once nothing references them.

## Capabilities

### New Capabilities

<!-- none -->

### Modified Capabilities

- `asset-pipeline`: the bundler is replaced (Shakapacker → Propshaft + importmap +
  tailwindcss-rails), and rich text is delivered via importmap instead of webpack.

## Impact

- `Gemfile` (add propshaft, importmap-rails, turbo-rails, stimulus-rails,
  tailwindcss-rails; remove shakapacker)
- `package.json` / `yarn.lock` (removed — importmap app has no app JS bundle)
- `config/` (importmap.rb, shakapacker.yml + webpack removed), `app/packs` →
  `app/assets` + `app/javascript`
- `Dockerfile` (asset build stage; keep runtime Node), `docker-compose.yml`
  (drop `webpack` service)
- GitHub issues: #279, #280, #281, #282, #283 (epic #296). Depends on the staging
  environment for validation.
