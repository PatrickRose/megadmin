## ADDED Requirements

### Requirement: An isolated staging environment mirrors production

The system SHALL provide a staging deployment that is isolated from production —
with its own database, object storage, and URL — so that changes can be validated
without affecting production data or users.

#### Scenario: Deploying to staging

- **WHEN** the staging deploy workflow runs for the target branch
- **THEN** the staging web and worker apps roll and migrations run against the
  `megadmin_staging` database, and production apps, database, and storage are
  untouched

### Requirement: Staging reuses shared platform resources

The system SHALL implement staging by reusing the shared Azure platform — the
Container Apps environment, PostgreSQL server, storage account, container
registry, and Key Vault — creating only staging-specific resources.

#### Scenario: Provisioning staging

- **WHEN** the staging Terraform is applied
- **THEN** it references the shared resources via data sources and creates only
  the `-staging` container apps, the `megadmin_staging` database, an
  `activestorage-staging` storage container, and a staging `SECRET_KEY_BASE`
  secret — using a Terraform state separate from production

### Requirement: Staging deploys via a parametrised GitHub Actions workflow

The system SHALL deploy staging through a reusable, parametrised GitHub Actions
workflow that targets the staging resources.

#### Scenario: Triggering a staging deploy

- **WHEN** the configured branch is pushed
- **THEN** a `deploy-staging` workflow builds the image, runs the staging
  migration job, rolls the staging apps, and passes the `/up` health check under
  the GitHub `staging` environment

### Requirement: Staging never sends real email

The system SHALL prevent staging from delivering email to real recipients.

#### Scenario: An email is sent from staging

- **WHEN** the app sends any email while running on staging
- **THEN** it is delivered to the Mailpit catcher and viewable in its UI, and no
  message is delivered to an external address
