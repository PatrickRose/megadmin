## Context

Production runs on Azure Container Apps, deployed by GitHub Actions and defined by
a single-environment Terraform module (`terraform/`) whose resources are keyed by
`var.environment` (default `production`). Running that module with
`environment = staging` would stamp out an entirely parallel platform — a new
Postgres server, a new Container Apps environment, a new VNet — which the project
owner does not want to pay for. The goal is an isolated staging deploy that reuses
the expensive shared resources.

## Goals / Non-Goals

**Goals:**
- Isolated staging: its own database, storage, and URL; a deploy there cannot
  touch production data or email real players.
- Reuse the shared platform: one Container Apps environment, one Postgres server,
  one storage account, one ACR/Key Vault.
- Zero risk to the live production Terraform state.

**Non-Goals:**
- A dedicated `staging.rb` Rails environment (staging runs the `production` env
  against isolated infra, driven by env vars).
- Refactoring production into a shared module now (possible later, out of scope).
- Custom DNS on day one (the auto Container Apps FQDN is enough to start).

## Decisions

- **Reuse the Container Apps Environment.** A CAE is a shared boundary with no
  per-app cost; staging apps run inside the existing `cae-megadmin-production`.
  Trade-off: staging shares the production Log Analytics workspace.
- **Reuse the Postgres server, add a logical database.** Extra databases on a
  flexible server are free; `megadmin_staging` gives isolated data without a
  second paid server. Sharing the *same* database is rejected — the migrate job
  would run migrations against production data.
- **Separate Terraform state + data sources.** Staging gets its own state key and
  references shared resources read-only via `data` sources, leaving the production
  state and the live (non-`-staging`-suffixed) prod apps untouched. Rejected
  alternative: one state with `for_each` over environments — it would try to
  rename/recreate the live production apps.
- **Mailpit for staging mail, provisioned via `azapi`.** Staging points SMTP at a
  Mailpit container app (already the local-dev mailer), a dead-end catcher, and
  drops the Mailgun secret. `azapi` is used because a Container App needs two
  ports (SMTP 1025 + UI 8025) and `azurerm` models only one ingress port.

## Risks / Trade-offs

- **Real email leaking from staging** → mitigated structurally by Mailpit (no
  external delivery path) rather than by configuration alone.
- **Shared Postgres compute** → a heavy staging query could affect production;
  acceptable for a low-traffic admin tool, and the staging DB role is scoped to
  the staging database only.
- **Shared Log Analytics workspace** → staging logs interleave with production;
  filterable by app name.

## Migration Plan

1. Apply the staging Terraform (creates only the new `-staging` resources).
2. Deploy the target branch via `deploy-staging.yml`; confirm `/up` and PDF
   rendering on the auto FQDN.
3. Optionally bind a `staging.` custom domain later.
Rollback: `terraform destroy` on the staging state removes only staging resources;
production is unaffected.

## Open Questions

- Access control for the staging URL (basic auth vs IP allowlist vs internal-only)
  — decide when wiring the Mailpit UI and app ingress.
