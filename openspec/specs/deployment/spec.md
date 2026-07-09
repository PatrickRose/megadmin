# Deployment

## Purpose

How megadmin is provisioned, built, and deployed. This spec captures the current
production setup on Azure Container Apps so that changes (e.g. adding a staging
environment) have a baseline to modify.

## Requirements

### Requirement: Production deploys via GitHub Actions to Azure Container Apps

The system SHALL deploy to production through a GitHub Actions workflow that
builds a Docker image, runs database migrations, rolls the web and worker
Container Apps, and verifies health before recording a release.

#### Scenario: CI passes on main

- **WHEN** the CI workflow completes successfully on `main` (or the deploy is
  dispatched manually)
- **THEN** the image is built and pushed to Azure Container Registry, the
  migration Container App Job runs, the web and worker Container Apps are updated,
  the `/up` health check passes, and a Sentry release is created

### Requirement: Infrastructure is defined in Terraform

The system SHALL define all Azure infrastructure as Terraform, with remote state
in an Azure Storage backend.

#### Scenario: Provisioning from scratch

- **WHEN** an operator runs `terraform apply`
- **THEN** the resource group, PostgreSQL flexible server, Container Apps
  environment, web/worker apps, migrate job, container registry, storage account,
  Key Vault, Log Analytics workspace, and virtual network are created

### Requirement: Runtime configuration comes from environment variables and Key Vault

The system SHALL source non-secret configuration from Container App environment
variables and secrets from Azure Key Vault.

#### Scenario: A container app starts

- **WHEN** a Container App revision starts
- **THEN** it reads the Postgres password, `SECRET_KEY_BASE`, storage access key,
  and SMTP password from Key Vault, and other settings from plain env vars
