## Why

With a modern pipeline and design tokens in place, the app should be re-skinned
from Bootstrap to Tailwind using the Pennine Megagames design system — a genuine
visual modernisation (new Gold & Plum palette, new fonts, light/dark) rather than
a like-for-like port. Encapsulating the design-system components as ViewComponents
keeps the ~318 sprawling Bootstrap class usages DRY and maps the code 1:1 to the
design system.

## What Changes

- Add **ViewComponent** and build the design-system components: Button, Icon,
  Card, Alert, DataTable, FormBox/FormField, Modal, plus the chrome
  (Masthead/SubNav/Footer).
- Rebuild the global chrome in Tailwind (gold masthead, sticky band sub-nav,
  footer, centred content column) and replace the single Bootstrap dropdown with a
  Stimulus controller.
- Replace **Bootstrap Icons** (and the custom SVGs) with **Font Awesome Free** via
  the Icon component.
- Replace the three hand-rolled popup scripts with a **Stimulus-driven modal**.
- Port all HAML views to Tailwind + the components, heaviest first.
- **BREAKING** (visual): remove Bootstrap CSS/JS and the old apricot SCSS palette
  once nothing references them.

## Capabilities

### New Capabilities

<!-- none -->

### Modified Capabilities

- `web-ui`: styling moves from Bootstrap to Tailwind + ViewComponents; icons move
  to Font Awesome Free; confirmations move to a Stimulus modal.

## Impact

- `Gemfile` (add `view_component`)
- `app/components` (new), `app/views/**` (ported to Tailwind), `app/javascript`
  (Stimulus controllers), `app/packs/styles/**` (Bootstrap SCSS removed)
- Depends on `design-tokens-and-theme` (themed utilities) and the pipeline change
- GitHub issues: #286, #287, #288, #289, #290, #291, #292, #293, #294, #295
  (epic #296)
