## REMOVED Requirements

### Requirement: JavaScript and CSS are bundled by Shakapacker

**Reason**: Shakapacker (webpack + SWC + Sass) is replaced by the modern Rails
default stack.
**Migration**: JavaScript is served via importmap (no bundler); CSS is compiled by
tailwindcss-rails; static assets are digested and served by Propshaft. The
`webpack` docker-compose service and `public/packs` output are removed.

## ADDED Requirements

### Requirement: JavaScript is served via importmap

The system SHALL deliver application JavaScript through importmap-rails, without a
JavaScript bundler.

#### Scenario: Loading a page

- **WHEN** a page loads in the browser
- **THEN** ES modules (Turbo, Stimulus, Trix/Action Text, app controllers) are
  served via importmap pins, with no webpack pack

### Requirement: CSS is compiled by tailwindcss-rails and served by Propshaft

The system SHALL compile CSS with tailwindcss-rails and serve digested static
assets with Propshaft.

#### Scenario: Precompiling assets

- **WHEN** `rails assets:precompile` runs during the Docker build
- **THEN** tailwindcss-rails compiles the stylesheet and Propshaft digests it,
  with no webpack invocation

#### Scenario: Local development

- **WHEN** the developer runs `bin/dev`
- **THEN** the Tailwind watcher rebuilds CSS on change alongside the Rails server

### Requirement: Hotwire provides client-side interactivity

The system SHALL use Turbo and Stimulus for client-side behaviour, replacing
`@rails/ujs`.

#### Scenario: Confirming a destructive action

- **WHEN** an organiser triggers an action that previously relied on
  `@rails/ujs` (e.g. `data-confirm`/`data-method`)
- **THEN** the behaviour is handled by Turbo or a Stimulus controller

## MODIFIED Requirements

### Requirement: Rich text editing is bundled through the pipeline

The system SHALL provide Trix / Action Text rich-text editing, with its
JavaScript pinned via importmap and its CSS served through Propshaft.

#### Scenario: Editing a brief

- **WHEN** an organiser opens a rich-text field
- **THEN** the Trix editor (pinned via importmap) renders and persists content via
  Action Text
