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
## DATABRICKS CURRENT USER DATA SOURCE
##
## This data block retrieves information about the current Service Principal from Databricks CLI.
##
## Providers:
## - `databricks.accounts`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
data "databricks_current_user" "this" {
  provider = databricks.accounts
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GROUP MEMBER RESOURCE
##
## This resource adds the current Service Principal to a Databricks group.
##
## Parameters:
## - `group_id`: The ID of the Databricks group.
## - `member_id`: The ID of the member to add to the group.
##
## Providers:
## - `databricks.accounts`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_group_member" "this" {
  provider  = databricks.accounts
  group_id  = var.databricks_administrator_group_id
  member_id = data.databricks_current_user.this.id
}
