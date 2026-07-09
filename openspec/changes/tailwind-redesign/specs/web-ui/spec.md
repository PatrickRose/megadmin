## REMOVED Requirements

### Requirement: UI is rendered with HAML templates styled with Bootstrap 5

**Reason**: Styling moves from Bootstrap 5 to Tailwind driven by the design tokens.
**Migration**: Views use Tailwind utilities (themed from `--pmg-*`); the Bootstrap
CSS/JS and the old apricot SCSS palette are removed.

### Requirement: Icons are provided by Bootstrap Icons and custom SVGs

**Reason**: Replaced by Font Awesome Free.
**Migration**: The Icon component maps former Bootstrap Icons glyphs to Font
Awesome names; the custom `edit-button.svg`/`rubbish-bin*.svg` are retired.

### Requirement: Confirmations use hand-rolled popup dialogs

**Reason**: Replaced by a Stimulus-driven modal.
**Migration**: The three bespoke popup scripts are replaced by a Modal component
backed by a Stimulus controller.

## ADDED Requirements

### Requirement: UI is styled with Tailwind

The system SHALL style its interface with Tailwind utilities themed from the
design tokens.

#### Scenario: Rendering a page

- **WHEN** a controller renders a view
- **THEN** the markup is styled with Tailwind utilities that resolve to the
  design-system tokens, with no Bootstrap classes

### Requirement: UI is composed from ViewComponents

The system SHALL build reusable UI as ViewComponents that map to the design system
(Button, Icon, Card, Alert, DataTable, FormBox/FormField, Modal, and chrome).

#### Scenario: Rendering a component

- **WHEN** a view needs a design-system element such as a button or card
- **THEN** it renders the corresponding ViewComponent, which has a unit test

### Requirement: Icons are provided by Font Awesome Free

The system SHALL render icons using Font Awesome Free via the Icon component.

#### Scenario: An action icon is shown

- **WHEN** a view renders an edit or delete action
- **THEN** the Icon component renders the corresponding Font Awesome Free glyph

### Requirement: Confirmations use a Stimulus-driven modal

The system SHALL confirm destructive or state-changing actions with a modal driven
by a Stimulus controller over a darkened scrim.

#### Scenario: Deleting a record

- **WHEN** an organiser clicks a delete or publish action
- **THEN** the Modal component (Stimulus-controlled) appears over a dark scrim to
  confirm

## MODIFIED Requirements

### Requirement: Buttons follow semantic variants

The system SHALL style action buttons in semantic variants — generic, success
(create/confirm), recommended (primary, gold), and danger (destructive) — via the
Button ViewComponent using the design tokens.

#### Scenario: Rendering a primary action

- **WHEN** a view renders the recommended action on a form
- **THEN** it renders the Button component's `recommended` variant (gold fill,
  dark text), visually distinct from generic, success, and danger
