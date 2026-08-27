# Shared platform — looked up read-only. Nothing here is managed by staging;
# these are the production resources staging reuses so it costs almost nothing.

data "azuread_client_config" "current" {}

locals {
  project_flat = replace(var.project_name, "-", "")
}

data "azurerm_resource_group" "shared" {
  name = "rg-${var.project_name}-${var.shared_environment}"
}

data "azurerm_container_app_environment" "shared" {
  name                = "cae-${var.project_name}-${var.shared_environment}"
  resource_group_name = data.azurerm_resource_group.shared.name
}

data "azurerm_container_registry" "shared" {
  name                = "acr${local.project_flat}${var.shared_environment}"
  resource_group_name = data.azurerm_resource_group.shared.name
}

data "azurerm_storage_account" "shared" {
  name                = "st${local.project_flat}${var.shared_environment}"
  resource_group_name = data.azurerm_resource_group.shared.name
}

data "azurerm_key_vault" "shared" {
  name                = "kv-${var.project_name}-${var.shared_environment}"
  resource_group_name = data.azurerm_resource_group.shared.name
}

data "azurerm_user_assigned_identity" "shared" {
  name                = "id-${var.project_name}-${var.shared_environment}"
  resource_group_name = data.azurerm_resource_group.shared.name
}

data "azurerm_postgresql_flexible_server" "shared" {
  name                = "psql-${var.project_name}-${var.shared_environment}"
  resource_group_name = data.azurerm_resource_group.shared.name
}

# Secrets reused as-is from the shared Key Vault (staging connects to the same
# Postgres server and storage account, so it can share these).
data "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-password"
  key_vault_id = data.azurerm_key_vault.shared.id
}

data "azurerm_key_vault_secret" "storage_access_key" {
  name         = "storage-access-key"
  key_vault_id = data.azurerm_key_vault.shared.id
}
