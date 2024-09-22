terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = "~> 1.39.0"
      configuration_aliases = [ databricks.workspace ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GROUP RESOURCE DEFINITION
##
## This resource block defines a group within Databricks.
## 
## Parameters:
## - `display_name`: Display name of the group. Example: "engineer_group"
## - `allow_cluster_create`: Whether the group is allowed to create clusters. Example: true
## - `allow_instance_pool_create`: Whether the group is allowed to create instance pools. Example: false
## - `databricks_sql_access`: Whether the group is allowed Databricks SQL access. Example: true
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_group" "this" {
  provider                   = databricks.workspace
  
  display_name               = var.group_name
  allow_cluster_create       = var.allow_cluster_create
  allow_instance_pool_create = var.allow_instance_pool_create
  databricks_sql_access      = var.allow_databricks_sql_access
}
