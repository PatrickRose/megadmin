output "resource_group_name" {
  value = azurerm_resource_group.main.name
}

output "acr_login_server" {
  value = azurerm_container_registry.main.login_server
}

output "web_app_url" {
  value = "https://${azurerm_container_app.web.ingress[0].fqdn}"
}

output "azure_client_id" {
  description = "Client ID for GitHub Actions OIDC (set as AZURE_CLIENT_ID secret)"
  value       = azuread_application.github_actions.client_id
}

output "azure_tenant_id" {
  description = "Tenant ID for GitHub Actions OIDC (set as AZURE_TENANT_ID secret)"
  value       = data.azuread_client_config.current.tenant_id
}

output "azure_subscription_id" {
  description = "Subscription ID for GitHub Actions OIDC (set as AZURE_SUBSCRIPTION_ID secret)"
  value       = var.subscription_id
}
