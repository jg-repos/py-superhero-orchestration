terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.86"
      configuration_aliases   = [ azurerm.auth_session, ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AZURERM_RESOURCE_GROUP DATA
##
## This data source retrieves information about an Azure resource group.
##
## Parameters:
## - `name`: The name of the Azure resource group.
## ---------------------------------------------------------------------------------------------------------------------
data "azurerm_resource_group" "this" {
  provider = azurerm.auth_session
  name     = var.azure_resource_group
}


## ---------------------------------------------------------------------------------------------------------------------
## RANDOM STRING RESOURCE
##
## This resource generates a random string of a specified length.
##
## Parameters:
## - `special`: Whether to include special characters in the random string.
## - `upper`: Whether to include uppercase letters in the random string.
## - `length`: The length of the random string.
## ---------------------------------------------------------------------------------------------------------------------
resource "random_string" "this" {
  special = false
  upper   = false
  length  = 4
}

locals {
  cloud   = "azure"
  program = "spark-databricks"
  project = "datasim"
}

locals  {
  prefix          = "${local.program}-${local.project}-${random_string.this.id}"
  storage_name = var.databricks_storage_name != null ? var.databricks_storage_name : "${local.prefix}-metastore-storage"
  tags            = merge(var.tags, {
    program = local.program
    project = local.project
    env     = "dev"
  })
}

## ---------------------------------------------------------------------------------------------------------------------
## AZURERM DATABRICKS ACCESS CONNECTOR RESOURCE
##
## This resource defines an access connector for Azure Databricks.
##
## Parameters:
## - `name`: The name of the access connector.
## - `resource_group_name`: The name of the resource group where the access connector will be created.
## - `location`: The location/region where the access connector will be deployed.
## - `identity`: Specifies the identity type for the access connector. Here, it's set to "SystemAssigned".
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_databricks_access_connector" "this" {
  provider            = azurerm.auth_session
  name                = substr("${local.storage_name}-access-connector", 0, 64)
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location

  identity {
    type = "SystemAssigned"
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AZURERM STORAGE ACCOUNT RESOUCE
##
## This resource defines an Azure Storage Account.
##
## Parameters:
## - `name`: The name of the storage account.
## - `resource_group_name`: The name of the resource group where the storage account will be created.
## - `location`: The location/region where the storage account will be deployed.
## - `account_tier`: The storage account tier, e.g., "Standard".
## - `account_replication_type`: The replication type for the storage account, e.g., "GRS" (Geo-redundant storage).
## - `is_hns_enabled`: Specifies whether Hierarchical Namespace (HNS) is enabled for the storage account.
## - `tags`: Tags to be applied to the storage account.
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_account" "this" {
  provider                 = azurerm.auth_session
  name                     = substr(replace("${local.storage_name}", "-", ""), 0, 24)
  resource_group_name      = data.azurerm_resource_group.this.name
  location                 = data.azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  is_hns_enabled           = true
  tags                     = local.tags
}


## ---------------------------------------------------------------------------------------------------------------------
## AZURERM STORAGE CONTAINER RESOURCE
##
## This resource defines a container within an Azure Storage Account.
##
## Parameters:
## - `name`: The name of the container.
## - `storage_account_name`: The name of the Azure Storage Account to which the container belongs.
## - `container_access_type`: The access type for the container, e.g., "private".
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_storage_container" "this" {
  provider              = azurerm.auth_session
  name                  = var.azure_container_name
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}


## ---------------------------------------------------------------------------------------------------------------------
## AZURERM ROLE ASSIGNMENT RESOURCE
##
## This resource assigns a role to a principal on a scope.
##
## Parameters:
## - `scope`: The scope at which the role assignment applies, in this case, the ID of the Azure Storage Account.
## - `role_definition_name`: The name of the role to assign, e.g., "Storage Blob Data Contributor".
## - `principal_id`: The principal to which the role is assigned, extracted from the identity of the databricks access connector.
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_role_assignment" "this" {
  provider             = azurerm.auth_session
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_access_connector.this.identity[0].principal_id
}
