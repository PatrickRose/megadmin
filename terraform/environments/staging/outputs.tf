output "resource_group_name" {
  description = "Staging resource group (holds the staging container apps + Mailpit)"
  value       = azurerm_resource_group.staging.name
}

output "web_app_url" {
  description = "Auto-assigned staging web URL (set as the staging GitHub environment URL and health-check target)"
  value       = "https://${azurerm_container_app.web.ingress[0].fqdn}"
}

output "database_name" {
  value = azurerm_postgresql_flexible_server_database.staging.name
}

output "azure_client_id_staging" {
  description = "Client ID of the staging deploy identity (set as the AZURE_CLIENT_ID secret in the GitHub `staging` environment)"
  value       = azuread_application.github_actions_staging.client_id
}

output "mailpit_app_name" {
  description = "Mailpit container app name (view captured mail via `az containerapp` port-forward to port 8025)"
  value       = azapi_resource.mailpit.name
}
