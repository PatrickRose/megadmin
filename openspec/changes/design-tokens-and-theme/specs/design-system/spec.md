## ADDED Requirements

### Requirement: Design tokens define the visual language

The system SHALL express its visual language as design tokens (colour, spacing,
typography, effects) sourced from the Pennine Megagames design system and defined
as CSS custom properties (`--pmg-*`).

#### Scenario: A component reads a colour

- **WHEN** a component needs the brand or a surface colour
- **THEN** it resolves to a `--pmg-*` custom property rather than a hard-coded hex

### Requirement: The Tailwind theme is derived from the design tokens

The system SHALL define Tailwind theme values that reference the `--pmg-*` tokens,
so that utility classes resolve to the design-system palette and type scale.

#### Scenario: Using a themed utility

- **WHEN** a template uses a themed utility such as `bg-brand` or `text-fg`
- **THEN** it renders the corresponding design-system token value

### Requirement: Light and dark themes are supported

The system SHALL support light and dark themes, activated automatically via
`prefers-color-scheme` and overridable via a `[data-theme]` attribute, driven by
the tokens.

#### Scenario: Switching theme

- **WHEN** the OS switches to dark mode, or an ancestor sets `data-theme="dark"`
- **THEN** themed colours change through the tokens with no per-utility `dark:`
  variants required

### Requirement: Brand typography uses Fredoka and Hanken Grotesk

The system SHALL use Fredoka for display/headings and Hanken Grotesk for body
text.

#### Scenario: Rendering headings and body

- **WHEN** a page renders
- **THEN** headings use Fredoka and body copy uses Hanken Grotesk
