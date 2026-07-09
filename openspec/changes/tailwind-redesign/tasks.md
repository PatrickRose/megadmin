## 1. Foundations

- [ ] 1.1 Add the `view_component` gem + an RSpec component test harness with a sample component (#286)
- [ ] 1.2 Rebuild the global chrome in Tailwind — gold masthead, sticky band sub-nav, footer, centred content column — and replace the Bootstrap dropdown with a Stimulus controller (#287)

## 2. Components

- [ ] 2.1 Icon component on Font Awesome Free (glyph map); retire the custom SVGs (#288)
- [ ] 2.2 Button component — variants generic/success/recommended/danger, sizes sm/md/icon (#289)
- [ ] 2.3 Card + Alert components; route flash messages through Alert (#290)
- [ ] 2.4 Modal component + Stimulus controller replacing the three hand-rolled popups (#293)

## 3. Views

- [ ] 3.1 DataTable component; port `events/index` and `event_signups/index` (#291)
- [ ] 3.2 FormBox/FormField components (simple_form + Trix); port the form views (#292)
- [ ] 3.3 Port the remaining views — teams, roles, devise, pages, play (#294)

## 4. Remove Bootstrap

- [ ] 4.1 Remove `bootstrap` + `@popperjs/core`, `twitter_bootstrap.scss`, `variables.scss`, and the old apricot SCSS palette; keep Font Awesome (#295)
- [ ] 4.2 Final `rubocop` + `rspec` + Playwright visual pass across key screens (light + dark); confirm zero Bootstrap references (#295)
