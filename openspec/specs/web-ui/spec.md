# Web UI

## Purpose

The application's user-interface conventions and components. This spec captures
the current Bootstrap-based UI so the Tailwind redesign has a baseline to modify.

## Requirements

### Requirement: UI is rendered with HAML templates styled with Bootstrap 5

The system SHALL render its interface using HAML templates styled with Bootstrap 5
and app-specific SCSS.

#### Scenario: Rendering a page

- **WHEN** a controller renders a view
- **THEN** the HAML template produces markup using Bootstrap 5 classes and the
  app's custom SCSS (masthead, sub-nav, footer, cards, tables, forms)

### Requirement: Icons are provided by Bootstrap Icons and custom SVGs

The system SHALL render icons using the Bootstrap Icons font plus a small set of
custom SVGs.

#### Scenario: An action icon is shown

- **WHEN** a view renders an edit or delete action
- **THEN** the icon comes from Bootstrap Icons or a bundled custom SVG
  (`edit-button.svg`, `rubbish-bin*.svg`)

### Requirement: Confirmations use hand-rolled popup dialogs

The system SHALL confirm destructive or state-changing actions with popup dialogs
implemented in bespoke JavaScript over a darkened screen.

#### Scenario: Deleting a record

- **WHEN** an organiser clicks a delete or publish action
- **THEN** a hand-rolled popup (e.g. `delete_button_popup.js`) appears over a dark
  overlay to confirm

### Requirement: Buttons follow semantic variants

The system SHALL style action buttons in semantic variants — generic, success
(create/confirm), recommended (primary), and danger (destructive).

#### Scenario: Rendering a primary action

- **WHEN** a view renders the recommended action on a form
- **THEN** it uses the recommended button variant, visually distinct from generic,
  success, and danger buttons
