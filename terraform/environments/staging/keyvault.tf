# Staging's own Rails signing key, stored alongside production's secrets in the
# shared Key Vault (a distinct secret name so it never collides with production).
#
# The identity running `terraform apply` needs the "Key Vault Secrets Officer"
# role on the shared Key Vault to create this. The production Terraform already
# grants that role to the deploying client (see terraform/environments/production/keyvault.tf); if a
# different operator runs staging, grant it to them first.
resource "azurerm_key_vault_secret" "secret_key_base_staging" {
  name         = "secret-key-base-staging"
  value        = random_password.secret_key_base.result
  key_vault_id = data.azurerm_key_vault.shared.id
}
