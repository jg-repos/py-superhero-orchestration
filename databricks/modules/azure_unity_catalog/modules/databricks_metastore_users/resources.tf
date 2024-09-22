terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = "~> 1.39.0"
      configuration_aliases = [ 
        databricks.accounts,
        databricks.workspace 
      ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS METASTORE ADMINS MODULE
##
## This module manages administrators for the Databricks Metastore.
##
## Parameters:
## - `databricks_workspace_id`: The ID of the Databricks workspace.
## - `databricks_user`: The user to assign as an administrator.
## - `databricks_group`: The group to assign as an administrator.
## - `permissions`: The permissions to assign to the administrators (e.g., ["ADMIN"]).
##
## Providers:
## - `databricks.accounts`: The Databricks provider for Accounts.
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
## This module manages service principals for the Databricks Metastore.
##
## Parameters:
## - `databricks_administrator_group_id`: The ID of the group containing Databricks administrators.
##
## Providers:
## - `databricks.accounts`: The Databricks provider for Accounts.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_metastore_service_principals" {
  source                                        = "./modules/service_principals"
  databricks_administrator_group_id             = module.databricks_metastore_admins.group_ip
  databricks_administrator_service_principal_id = var.databricks_administrator_service_principal_id

  providers = {
    databricks.accounts = databricks.accounts
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS METASTORE USERS MODULE
##
## This module manages users for the Databricks Metastore.
##
## Parameters:
## - `databricks_workspace_id`: The ID of the Databricks workspace.
## - `databricks_user`: The username of the Databricks administrator.
## - `databricks_group`: The name of the Databricks user group.
##
## Providers:
## - `databricks.accounts`: The Databricks provider for Accounts.
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
