## Why

The modernisation rewrites the asset pipeline and Dockerfile build, which is
exactly the kind of change that can break a deploy (asset precompile, PDF
runtime, image boot). There is currently no way to prove a deploy works without
shipping to production. A cheap, isolated staging environment de-risks the whole
initiative — and every future change.

## What Changes

- Add an **isolated staging deployment** on Azure Container Apps that **reuses**
  the existing platform rather than duplicating it (no second database server, no
  second Container Apps environment).
- New staging Terraform with a **separate state**, referencing shared resources
  (CAE, Postgres server, storage account, ACR, Key Vault, VNet) via `data`
  sources and creating only the staging-specific resources: `-staging` web/worker
  apps + migrate job, a `megadmin_staging` logical database, an
  `activestorage-staging` container, and a `secret-key-base-staging` secret.
- Add a **Mailpit** mail-catcher container app so staging can **never** send real
  email to players.
- Parametrise `deploy.yml` into a reusable workflow and add a branch-triggered
  `deploy-staging.yml` targeting the staging resources.
- Remove the vestigial `qa.rb` / `demo.rb` Rails environments left from the app's
  origin.

## Capabilities

### New Capabilities

<!-- none -->

### Modified Capabilities

- `deployment`: adds requirements for an isolated staging environment, shared
  platform reuse, a parametrised deploy workflow, and non-delivering staging mail.

## Impact

- `terraform/` (new staging configuration + shared-resource data sources)
- `.github/workflows/deploy.yml` (refactor to reusable) + new `deploy-staging.yml`
- `config/environments/` (remove `qa.rb`, `demo.rb`)
- GitHub Environments/secrets (`staging`)
- GitHub issues: #275, #276, #277, #278 (epic #296)
