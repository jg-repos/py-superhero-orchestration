terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.86",
      configuration_aliases = [ azurerm.auth_session ]
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.39.0"
      configuration_aliases = [ 
        databricks.accounts,
        databricks.workspace
       ]
    }
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AZURE RESOURCE GROUP DATA SOURCE
##
## This data source retrieves information about an existing Azure resource group.
##
## Parameters:
## - `name`: The name of the Azure resource group.
## ---------------------------------------------------------------------------------------------------------------------
data "azurerm_resource_group" "this" {
  provider   = azurerm.auth_session
  depends_on = [
    module.databricks_admin_group,
    module.databricks_user_group
  ]

  name       = var.azure_resource_group_name
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
  prefix               = var.resource_prefix != null ? var.resource_prefix : "${local.program}-${local.project}-${random_string.this.id}"
  unity_catalog_name   = var.databricks_unity_catalog_name != null ? var.databricks_unity_catalog_name : "${local.prefix}-databricks-unity-catalog"
  
  tags                 = merge(var.tags, {
    program = local.program
    project = local.project
    env     = "dev"
  })
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS ADMIN GROUP MODULE
##
## This module creates a Databricks group with administrative privileges.
##
## Parameters:
## - `group_name`: The name of the Databricks group.
## - `allow_cluster_create`: Whether to allow creating clusters.
## - `allow_databricks_sql_access`: Whether to allow access to Databricks SQL.
## - `allow_instance_pool_create`: Whether to allow creating instance pools.
##
## Providers:
## - `databricks.workspace`: The Databricks provider for managing workspace resources.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_admin_group" {
  source                      = "../databricks_group"
  group_name                  = "${local.unity_catalog_name}-admin-group"
  allow_cluster_create        = true
  allow_databricks_sql_access = true
  allow_instance_pool_create  = true

  providers = {
    databricks.workspace = databricks.accounts
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS USER GROUP MODULE
##
## This module creates a Databricks group with user privileges.
##
## Parameters:
## - `group_name`: The name of the Databricks group.
## - `allow_databricks_sql_access`: Whether to allow access to Databricks SQL.
##
## Providers:
## - `databricks.workspace`: The Databricks provider for managing workspace resources.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_user_group" {
  source                      = "../databricks_group"
  group_name                  = "${local.unity_catalog_name}-user-group"
  allow_databricks_sql_access = true

  providers = {
    databricks.workspace = databricks.accounts
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AZURE METASTORE BUCKET MODULE
##
## This module creates an Azure storage account for metastore data.
##
## Parameters:
## - `databricks_storage_credential_name`: The name of the Databricks storage credential.
## - `azure_resource_group`: The name of the Azure resource group.
## - `tags`: Tags to apply to the Azure storage account.
##
## Providers:
## - `azurerm.auth_session`: The Azure provider for managing authentication.
## ---------------------------------------------------------------------------------------------------------------------
module "azure_metastore_bucket" {
  source     = "./modules/azure_metastore_bucket"
  depends_on = [
    data.azurerm_resource_group.this,
    module.databricks_admin_group,
    module.databricks_user_group
  ]

  databricks_storage_name = "metastore${local.unity_catalog_name}"
  azure_resource_group    = var.azure_resource_group_name
  tags                    = local.tags
  
  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AZURE EXTERNAL STORAGE BUCKET MODULE
##
## This module creates an Azure storage account for metastore data.
##
## Parameters:
## - `databricks_storage_credential_name`: The name of the Databricks storage credential.
## - `azure_resource_group`: The name of the Azure resource group.
## - `tags`: Tags to apply to the Azure storage account.
##
## Providers:
## - `azurerm.auth_session`: The Azure provider for managing authentication.
## ---------------------------------------------------------------------------------------------------------------------
/*
module "azure_external_storage_bucket" {
  source     = "./modules/azure_metastore_bucket"
  depends_on = [
    data.azurerm_resource_group.this,
    module.databricks_admin_group,
    module.databricks_user_group
  ]

  databricks_storage_name = "external${local.prefix}"
  azure_resource_group    = var.azure_resource_group_name
  azure_container_name    = "external"
  tags                    = local.tags
  
  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}
*/

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS METASTORE RESOURCE
##
## This resource defines a Databricks metastore for Unity Catalog.
##
## Parameters:
## - `name`: The name of the Databricks metastore.
## - `region`: The region where the Databricks metastore is located.
## - `owner`: The name of the owner group for the Databricks metastore.
## - `storage_root`: The root URL of the external storage associated with the metastore.
## - `force_destroy`: Whether to force destroy the Databricks metastore.
##
## Providers:
## - `databricks.accounts`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_metastore" "this" {
  provider      = databricks.accounts  
  name          = "${local.unity_catalog_name}-meta-store"
  region        = data.azurerm_resource_group.this.location
  owner         = module.databricks_admin_group.databricks_group_name
  storage_root  = module.azure_metastore_bucket.databricks_external_location_url
  force_destroy = true
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS METASTORE ASSIGNMENT RESOURCE
##
## This resource assigns a Databricks metastore to a workspace.
##
## Parameters:
## - `workspace_id`: The ID of the Databricks workspace.
## - `metastore_id`: The ID of the Databricks metastore.
## - `default_catalog_name`: The name of the default catalog associated with the metastore.
##
## Providers:
## - `databricks.accounts`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_metastore_assignment" "this" {
  provider             = databricks.accounts
  workspace_id         = var.databricks_workspace_number
  metastore_id         = databricks_metastore.this.id
  default_catalog_name = var.databricks_default_catalog_name
}


## ---------------------------------------------------------------------------------------------------------------------
## TIME_SLEEP RESOURCE
##
## This resource adds a delay to wait for the workspace to enable identity federation.
##
## Parameters:
## - `create_duration`: The duration to wait before completing module databricks_metastore_user_management.
##
## Dependencies:
## - `databricks_metastore_assignment.this`: The Databricks metastore assignment resource.
## ---------------------------------------------------------------------------------------------------------------------
resource "time_sleep" "wait_for_permission_apis" {
  depends_on       = [
    databricks_metastore_assignment.this
  ]
  create_duration  = "120s"  # Adjust the duration as needed
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS_METASTORE_USER_MANAGEMENT MODULE
##
## This module manages users for Databricks Metastore.
##
## Parameters:
## - `databricks_account_id`: The Databricks account ID.
## - `databricks_workspace_id`: The Databricks workspace ID.
## - `databricks_administrator`: The administrator for Databricks.
## - `databricks_administrator_group`: The group name for Databricks administrators.
## - `databricks_user_group`: The group name for Databricks users.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_metastore_user_management" {
  source                   = "./modules/databricks_metastore_users"
  depends_on               = [ 
    time_sleep.wait_for_permission_apis,
    module.databricks_admin_group,
    module.databricks_user_group 
  ]

  databricks_account_id                         = var.databricks_account_id
  databricks_workspace_id                       = var.databricks_workspace_number
  databricks_administrator                      = var.databricks_administrator
  databricks_administrator_service_principal_id = var.databricks_administrator_service_principal_id
  databricks_administrator_group                = module.databricks_admin_group.databricks_group_name
  databricks_user_group                         = module.databricks_user_group.databricks_group_name

  providers = {
    databricks.accounts = databricks.accounts
    databricks.workspace = databricks.workspace
  }
}

resource "databricks_grants" "this" {
  provider   = databricks.workspace
  depends_on = [ module.databricks_metastore_user_management ]

  metastore  = databricks_metastore.this.id
  grant {
    principal  = module.databricks_admin_group.databricks_group_name
    privileges = ["CREATE_CATALOG", "CREATE_EXTERNAL_LOCATION"]
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS_EXTERNAL_LOCATION MODULE
##
## This module configures an external location in Databricks.
##
## Parameters:
## - `databricks_storage_credential_name`: The name of the Databricks storage credential.
## - `databricks_access_connector_id`: The ID of the Databricks access connector.
## - `databricks_external_location_url`: The URL of the Databricks external location.
## ---------------------------------------------------------------------------------------------------------------------
/*
module "databricks_external_location" {
  source                             = "./modules/databricks_external_location"
  depends_on                         = [ 
    module.azure_external_storage_bucket,
    databricks_grants.this 
  ]
  
  databricks_storage_credential_name = local.unity_catalog_name
  databricks_access_connector_id     = module.azure_external_storage_bucket.access_connector_id
  databricks_external_location_url   = module.azure_external_storage_bucket.databricks_external_location_url

  providers = {
    databricks.workspace = databricks.workspace
  }
}
*/

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS_METASTORE_DATA_ACCESS RESOURCE
##
## This resource configures data access for the Databricks metastore.
##
## Parameters:
## - `metastore_id`: The ID of the Databricks metastore.
## - `name`: The name of the data access configuration.
## - `azure_managed_identity`: Configuration for Azure managed identity.
##     - `access_connector_id`: The ID of the Databricks access connector.
## - `is_default`: Whether this data access configuration is the default.
## ---------------------------------------------------------------------------------------------------------------------
/*
resource "databricks_metastore_data_access" "this" {
  provider     = databricks.workspace
  depends_on = [ 
    databricks_grants.this,
    module.azure_metastore_bucket ]

  metastore_id = databricks_metastore.this.id
  name         = "${local.unity_catalog_name}-data-access"
  azure_managed_identity {
    access_connector_id = module.azure_metastore_bucket.access_connector_id
  }
  is_default = true
  force_destroy = true
}
*/