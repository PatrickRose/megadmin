# Staging environment

An isolated staging deploy on Azure Container Apps that **reuses** the production
platform. It creates only staging-specific resources; the Postgres server,
Container Apps environment, storage account, ACR, and Key Vault are shared
(looked up read-only in `data.tf`). Uses its own Terraform state
(`megadmin-staging.tfstate`), so a staging apply can never touch production.

Implements OpenSpec change `openspec/changes/staging-environment` (GitHub #275, #276, #277).

## What it creates

| Resource | Name |
|---|---|
| Resource group | `rg-megadmin-staging` |
| Logical database (on shared server) | `megadmin_staging` |
| Storage container (on shared account) | `activestorage-staging` |
| Key Vault secret (in shared KV) | `secret-key-base-staging` |
| Web / worker container apps | `ca-megadmin-staging-web` / `-worker` |
| Migration job | `caj-megadmin-staging-migrate` |
| Mailpit mail-catcher | `ca-megadmin-staging-mail` |
| Deploy identity (app registration + SP) | `megadmin-github-actions-staging` |

Net new **paid** resources: three scale-to-zero container apps + one small
always-on Mailpit app. No second database server, no second Container Apps
environment.

## Prerequisites

- The production platform (`terraform/environments/production/`) is already applied.
- The identity running `terraform apply` needs **Key Vault Secrets Officer** on
  the shared `kv-megadmin-production` (production's Terraform already grants this
  to the deploying client) and directory permission to create an app registration.

## Setup

```bash
cd terraform/environments/staging
cp terraform.tfvars.example terraform.tfvars   # fill in subscription_id
terraform init
terraform plan     # should show ONLY new -staging resources + the logical DB/container/secret
terraform apply
```

Then wire GitHub Actions:

```bash
terraform output azure_client_id_staging   # -> AZURE_CLIENT_ID in the GitHub `staging` environment
terraform output web_app_url                # -> the staging environment URL
```

Create a GitHub **Environment** named `staging` (Settings → Environments) and set
its `AZURE_CLIENT_ID` secret to the value above. `AZURE_TENANT_ID` and
`AZURE_SUBSCRIPTION_ID` are shared with production. The `deploy-staging.yml`
workflow then deploys the `staging` branch automatically.

## Email

Staging points SMTP at Mailpit and sets no `SMTP_USERNAME`, so
`config/application.rb` sends with `authentication: nil` — real email can never
leave staging. View captured mail on the Mailpit UI (port 8025); it is internal
by default, so reach it with `az containerapp` port-forwarding, or set
`external = true` + `MP_UI_AUTH` in `mailpit.tf` for a bookmarkable URL.

## Teardown

`terraform destroy` removes only the staging resources (including the logical DB,
storage container, and KV secret). Production is unaffected.
