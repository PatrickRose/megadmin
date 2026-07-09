## Why

The redesign needs a single source of visual truth. The Pennine Megagames design
system provides token-based colour, type, spacing, and effects with full light +
dark support. Importing those tokens and deriving the Tailwind theme from them
keeps the design system and the app in sync, and makes dark mode fall out of the
tokens automatically.

## What Changes

- Import the design-system tokens (`colors`, `spacing`, `typography`, `fonts`,
  `effects`) into the repo as CSS custom properties (`--pmg-*`).
- Vendor **Font Awesome Free** (CSS + webfonts) and the logo assets into the
  Propshaft asset path (self-hosted, no CDN).
- Load the brand fonts **Fredoka** (display) and **Hanken Grotesk** (body).
- Wire Tailwind v4 `@theme` values to the `--pmg-*` tokens so utilities resolve to
  the design-system palette, and light/dark switch through the tokens.

## Capabilities

### New Capabilities

- `design-system`: the token set, the Tailwind theme derived from it, brand
  typography, and light/dark theming.

### Modified Capabilities

<!-- none -->

## Impact

- `app/assets` (imported tokens, vendored Font Awesome + fonts + logo)
- `app/assets/tailwind/application.css` (`@theme` mapping)
- Depends on `asset-pipeline-modernisation` (tailwindcss-rails must exist)
- GitHub issues: #284, #285 (epic #296)
