terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.86"
      configuration_aliases = [
        azurerm.auth_session,
      ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AZURE STORAGE ACCOUNT DATA BLOCK
##
## This data source retrieves information about an Azure Storage Account.
## 
## Parameters:
## - `provider`: The Azure provider configuration.
## - `name`: The name of the storage account.
## - `resource_group_name`: The name of the resource group where the storage account is located.
## ---------------------------------------------------------------------------------------------------------------------
data "azurerm_storage_account" "this" {
  provider            = azurerm.auth_session
  name                = var.bucket_name
  resource_group_name = var.resource_group_name
}



## ---------------------------------------------------------------------------------------------------------------------
## AZURE ROLE ASSIGNMENT RESOURCE
##
## This resource assigns a role to a security principal for an Azure resource.
## 
## Parameters:
## - `provider`: The Azure provider configuration.
## - `scope`: The ID of the Azure resource to which the role is assigned.
## - `role_definition_name`: The name of the role to assign.
## - `principal_id`: The ID of the security principal (e.g., user, group, service principal) to which the role is assigned.
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_role_assignment" "this" {
  provider             = azurerm.auth_session
  scope                = data.azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.security_group_id
}
