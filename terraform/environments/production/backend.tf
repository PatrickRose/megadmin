terraform {
  backend "azurerm" {
    resource_group_name  = "rg-megadmin-tfstate"
    storage_account_name = "stmegadmintfstate"
    container_name       = "tfstate"
    key                  = "megadmin.tfstate"
  }
}
