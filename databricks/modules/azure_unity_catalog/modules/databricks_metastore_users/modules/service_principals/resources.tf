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
## DATABRICKS CURRENT USER DATA
##
## Retrieves information about the current Service Principal in Databricks.
## ---------------------------------------------------------------------------------------------------------------------
data "databricks_current_user" "this" {
  provider = databricks.workspace
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GROUP MEMBER RESOURCE
##
## Adds the current Service Principal as a member of a Databricks group.
##
## Parameters:
## - `group_id`: The ID of the Databricks group.
## - `member_id`: The ID of the member to add to the group.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_group_member" "this" {
  provider  = databricks.accounts
  group_id  = var.databricks_administrator_group_id
  member_id = data.databricks_current_user.this.id
}

resource "databricks_service_principal_role" "account_admin" {
  provider             = databricks.accounts
  service_principal_id = data.databricks_current_user.this.id
  role                 = "account_admin"
}