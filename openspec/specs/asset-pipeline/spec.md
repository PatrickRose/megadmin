# Asset Pipeline

## Purpose

How front-end JavaScript and CSS are built and served. This spec captures the
current Shakapacker (webpack) setup so the modernisation change has a baseline to
modify.

## Requirements

### Requirement: JavaScript and CSS are bundled by Shakapacker

The system SHALL build JavaScript and CSS through Shakapacker (webpack), with SWC
for JS transpilation and Sass for stylesheets, emitting packs served from
`public/packs`.

#### Scenario: Assets are precompiled for production

- **WHEN** `rails assets:precompile` runs during the Docker build
- **THEN** webpack bundles the JS and CSS entrypoints under `app/packs` into
  digested packs served from `public/packs`

#### Scenario: Local development

- **WHEN** the app runs under docker-compose
- **THEN** a `webpack` dev-server service (`bin/shakapacker-dev-server`) builds and
  serves assets

### Requirement: Rich text editing is bundled through the pipeline

The system SHALL provide Trix / Action Text rich-text editing, with its
JavaScript and CSS delivered through the asset pipeline.

#### Scenario: Editing a brief

- **WHEN** an organiser opens a rich-text field
- **THEN** the Trix editor (bundled by webpack) renders and persists content via
  Action Text
