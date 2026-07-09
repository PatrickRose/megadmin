## 1. Import tokens & assets (#284)

- [ ] 1.1 Import the Pennine Megagames tokens (`colors`, `spacing`, `typography`, `fonts`, `effects`) into the repo as `--pmg-*` custom properties
- [ ] 1.2 Vendor Font Awesome Free CSS + webfonts into the Propshaft asset path; vendor the logo assets
- [ ] 1.3 Verify an FA glyph and a token colour render on a test view

## 2. Theme wiring (#285)

- [ ] 2.1 Map Tailwind v4 `@theme` values to the `--pmg-*` tokens (e.g. `bg-brand`, `text-fg`, `shadow-panel`); load Fredoka + Hanken Grotesk
- [ ] 2.2 Verify utilities resolve to the design-system palette/type and that light/dark switch through the tokens with no `dark:` variants needed for theme colours
