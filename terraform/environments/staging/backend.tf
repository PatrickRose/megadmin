terraform {
  # Separate state file from production, in the same backend storage account.
  # Production state lives at key "megadmin.tfstate" (see terraform/backend.tf);
  # staging is isolated here so a staging apply can never touch production state.
  backend "azurerm" {
    resource_group_name  = "rg-megadmin-tfstate"
    storage_account_name = "stmegadmintfstate"
    container_name       = "tfstate"
    key                  = "megadmin-staging.tfstate"
  }
}
