resource "azurerm_key_vault" "main" {
  name                       = "kv-${var.project_name}-${var.environment}"
  resource_group_name        = azurerm_resource_group.main.name
  location                   = azurerm_resource_group.main.location
  tenant_id                  = data.azuread_client_config.current.tenant_id
  sku_name                   = "standard"
  rbac_authorization_enabled = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = var.tags
}

resource "azurerm_role_assignment" "keyvault_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.container_app.principal_id
}

resource "azurerm_role_assignment" "keyvault_secrets_officer" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azuread_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "postgres_password" {
  name         = "postgres-password"
  value        = var.postgres_admin_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.keyvault_secrets_officer]
}

resource "azurerm_key_vault_secret" "secret_key_base" {
  name         = "secret-key-base"
  value        = var.secret_key_base
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.keyvault_secrets_officer]
}

resource "azurerm_key_vault_secret" "rails_master_key" {
  name         = "rails-master-key"
  value        = var.rails_master_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.keyvault_secrets_officer]
}

resource "azurerm_key_vault_secret" "storage_access_key" {
  name         = "storage-access-key"
  value        = azurerm_storage_account.main.primary_access_key
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.keyvault_secrets_officer]
}

resource "azurerm_key_vault_secret" "smtp_password" {
  name         = "smtp-password"
  value        = var.smtp_password
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.keyvault_secrets_officer]
}
