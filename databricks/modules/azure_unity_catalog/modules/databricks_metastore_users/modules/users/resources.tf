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
## DATABRICKS USER DATA
##
## Retrieves information about a Databricks user.
##
## Parameters:
## - `user_name`: The username of the Databricks user.
## ---------------------------------------------------------------------------------------------------------------------
data "databricks_user" "this" {
  provider  = databricks.accounts
  user_name = var.databricks_user
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GROUP DATA
##
## Retrieves information about a Databricks group.
##
## Parameters:
## - `display_name`: The display name of the Databricks group.
## ---------------------------------------------------------------------------------------------------------------------
data "databricks_group" "this" {
  provider     = databricks.accounts
  display_name = var.databricks_group
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS MWS PERMISSION ASSIGNMENT RESOURCE
##
## Assigns permissions to a group in Databricks.
##
## Parameters:
## - `workspace_id`: The ID of the Databricks workspace.
## - `principal_id`: The ID of the group to which permissions are assigned.
## - `permissions`: The list of permissions to assign.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_mws_permission_assignment" "this" {
  provider     = databricks.accounts
  workspace_id = var.databricks_workspace_id
  principal_id = data.databricks_group.this.id
  permissions  = var.permissions
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GROUP MEMBER RESOURCE
##
## Adds a user to a group in Databricks.
##
## Parameters:
## - `group_id`: The ID of the Databricks group.
## - `member_id`: The ID of the user to add to the group.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_group_member" "this" {
  provider   = databricks.accounts
  depends_on = [databricks_mws_permission_assignment.this]
  group_id   = data.databricks_group.this.id
  member_id  = data.databricks_user.this.id
}
