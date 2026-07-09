## 1. Staging infrastructure (#275)

- [x] 1.1 Add a staging Terraform configuration with a separate state key, referencing the shared CAE, Postgres server, storage account, ACR, Key Vault, user-assigned identity, and VNet/subnets via `data` sources
- [x] 1.2 Create the staging resources: `ca-megadmin-staging-web`, `-worker`, `caj-megadmin-staging-migrate`, the `megadmin_staging` database, the `activestorage-staging` container, and the `secret-key-base-staging` Key Vault secret
- [ ] 1.3 Confirm `terraform plan` shows only new `-staging` resources and leaves the production plan unchanged

## 2. Mailpit mail-catcher (#276)

- [x] 2.1 Add a `ca-megadmin-staging-mail` container app (`axllent/mailpit`, `min_replicas=1`) via the `azapi` provider, exposing SMTP `1025` and UI `8025`
- [ ] 2.2 Point the staging web/worker SMTP env at Mailpit and drop the Mailgun secret; secure the UI (internal + port-forward, or `MP_UI_AUTH` + IP allowlist)

## 3. Deploy workflow (#277)

- [x] 3.1 Refactor `.github/workflows/deploy.yml` into a reusable workflow parametrised by resource group, app names, migrate job, URL, GitHub environment, and Sentry environment
- [ ] 3.2 Add `deploy-staging.yml` calling it against the staging resources; create the GitHub `staging` environment and secrets; branch-triggered
- [ ] 3.3 Deploy the branch to staging and verify `/up` and PDF rendering on the auto FQDN

## 4. Cleanup (#278)

- [ ] 4.1 Remove the vestigial `config/environments/qa.rb` and `demo.rb` and any references; keep the suite green
