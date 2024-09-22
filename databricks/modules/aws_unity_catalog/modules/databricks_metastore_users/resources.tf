terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = "~> 1.39.0"
      configuration_aliases = [ databricks.accounts ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS METASTORE ADMINS MODULE
##
## This module manages the administrators of the Databricks Metastore.
##
## Parameters:
## - `databricks_workspace_id`: The ID of the Databricks workspace.
## - `databricks_user`: The user who will be granted admin permissions.
## - `databricks_group`: The group whose members will be granted admin permissions.
## - `permissions`: The permissions to grant to the administrators (e.g., ["ADMIN"]).
##
## Providers:
## - `databricks.accounts`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_metastore_admins" {
  source                  = "./modules/users"
  databricks_workspace_id = var.databricks_workspace_id
  databricks_user         = var.databricks_administrator
  databricks_group        = var.databricks_administrator_group
  permissions             = ["ADMIN"]

  providers = {
    databricks.accounts = databricks.accounts
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS METASTORE SERVICE PRINCIPALS MODULE
##
## This module manages the service principals for the Databricks Metastore.
##
## Parameters:
## - `databricks_administrator_group_id`: The ID of the group containing the Databricks Metastore administrators.
##
## Providers:
## - `databricks.accounts`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_metastore_service_principals" {
  source                                     = "./modules/service_principals"
  databricks_administrator_group_id          = module.databricks_metastore_admins.group_ip

  providers = {
    databricks.accounts = databricks.accounts
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS METASTORE USERS MODULE
##
## This module manages the users for the Databricks Metastore.
##
## Parameters:
## - `databricks_workspace_id`: The ID of the Databricks workspace.
## - `databricks_user`: The username of the Databricks administrator.
## - `databricks_group`: The name of the Databricks user group.
##
## Providers:
## - `databricks.accounts`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_metastore_users" {
  source                  = "./modules/users"
  databricks_workspace_id = var.databricks_workspace_id
  databricks_user         = var.databricks_administrator
  databricks_group        = var.databricks_user_group

  providers = {
    databricks.accounts = databricks.accounts
  }
}
