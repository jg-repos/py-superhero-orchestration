terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = "~> 1.39.0"
      configuration_aliases = [ databricks.accounts ]
    }
    google = {
      source  = "hashicorp/google"
      version = "4.47.0"
      configuration_aliases = [ google.auth_session ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS USER DATA SOURCE
##
## This data source retrieves information about a Databricks user.
##
## Parameters:
## - `user_name`: The username of the Databricks user.
##
## Providers:
## - `databricks.accounts`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
data "databricks_user" "this" {
  provider  = databricks.accounts
  user_name = var.databricks_user
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GROUP DATA
##
## This data source retrieves information about a Databricks group.
##
## Parameters:
## - `display_name`: The display name of the Databricks group.
##
## Providers:
## - `databricks.accounts`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
data "databricks_group" "this" {
  provider     = databricks.accounts
  display_name = var.databricks_group
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS MWS PERMISSION ASSIGNMENT
##
## This resource assigns permissions to a principal (user or group) in a Databricks workspace.
##
## Parameters:
## - `workspace_id`: The ID of the Databricks workspace.
## - `principal_id`: The ID of the principal (user or group) to which permissions are assigned.
## - `permissions`: The list of permissions to assign to the principal.
##
## Providers:
## - `databricks.accounts`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_mws_permission_assignment" "this" {
  provider     = databricks.accounts
  workspace_id = var.databricks_workspace_id
  principal_id = data.databricks_group.this.id
  permissions  = var.permissions
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GROUP MEMBER
##
## This resource adds a member (user) to a group in a Databricks workspace.
##
## Parameters:
## - `group_id`: The ID of the group to which the member is added.
## - `member_id`: The ID of the member (user) to add to the group.
##
## Providers:
## - `databricks.accounts`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_group_member" "this" {
  provider   = databricks.accounts
  depends_on = [databricks_mws_permission_assignment.this]
  group_id   = data.databricks_group.this.id
  member_id  = data.databricks_user.this.id
}

resource "google_storage_bucket_iam_member" "this" {
  provider = google.auth_session
  bucket   = var.gcp_metastore_bucket_name
  role     = var.gcp_roles
  member   = "user:${var.databricks_user}"
}