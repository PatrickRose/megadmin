# Staging-specific resources. The expensive platform (Postgres server, Container
# Apps environment, storage account, ACR, Key Vault, VNet) is reused via data
# sources in data.tf — the only new paid resources here are three scale-to-zero
# container apps plus a small always-on Mailpit catcher.

# A dedicated resource group for staging keeps teardown a one-liner and keeps
# staging resources visibly separate from production. Sub-resources of shared
# services (the logical DB, storage container, KV secret) live with their
# parents in the production RG by nature.
resource "azurerm_resource_group" "staging" {
  name     = "rg-${var.project_name}-staging"
  location = var.location
  tags     = var.tags
}

# Isolated database on the SHARED Postgres server — free (you pay for the server,
# not per database), but keeps staging data fully separate from production.
resource "azurerm_postgresql_flexible_server_database" "staging" {
  name      = "${var.project_name}_staging"
  server_id = data.azurerm_postgresql_flexible_server.shared.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Isolated Active Storage container on the SHARED storage account.
resource "azurerm_storage_container" "staging" {
  name                  = "activestorage-staging"
  storage_account_id    = data.azurerm_storage_account.shared.id
  container_access_type = "private"
}
