# A dedicated deploy identity for staging, kept entirely in staging state so the
# production Terraform/service principal is untouched. It can push to the shared
# ACR and manage only the staging resource group.
resource "azuread_application" "github_actions_staging" {
  display_name = "${var.project_name}-github-actions-staging"
}

resource "azuread_service_principal" "github_actions_staging" {
  client_id = azuread_application.github_actions_staging.client_id
}

# Federated credential for the GitHub `staging` environment. When the staging
# deploy job declares `environment: staging`, its OIDC token carries this subject.
resource "azuread_application_federated_identity_credential" "staging" {
  application_id = azuread_application.github_actions_staging.id
  display_name   = "github-actions-staging"
  description    = "GitHub Actions OIDC for ${var.github_repository} (staging environment)"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_repository}:environment:staging"
}

# Manage only the staging RG (rolls the staging apps + runs the migrate job).
resource "azurerm_role_assignment" "staging_contributor" {
  scope                = azurerm_resource_group.staging.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions_staging.object_id
}

# Push images to the shared registry.
resource "azurerm_role_assignment" "staging_acr_push" {
  scope                = data.azurerm_container_registry.shared.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.github_actions_staging.object_id
}
