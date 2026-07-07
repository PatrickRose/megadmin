# Development workflow

## Commits
- Make **small, targeted commits**, one per logical concern. Do not bundle unrelated
  changes into a single large commit.
- Each commit should leave the test suite green.

## Test-Driven Development (TDD)
Follow a TDD approach for new behaviour and bug fixes:
1. **Red** — write a failing test that describes the desired behaviour first.
2. **Green** — write the minimum code needed to make the test pass.
3. **Refactor** — clean up while keeping the tests green.

Prefer committing the failing test and its implementation together as one focused commit
per behaviour, so each commit is self-contained and green.

## Running the app and tests
This is a Docker-based Rails app. Run commands inside the `web` container:
- Tests: `docker compose exec -e RAILS_ENV=test web bundle exec rspec`
- Linter: `docker compose exec web bundle exec rubocop`

## Pre-commit checklist
- Run rubocop and fix any new offences.
- Run rspec and ensure the suite is green.
