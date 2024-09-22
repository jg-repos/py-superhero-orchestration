terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = "~> 1.39.0"
      configuration_aliases = [ databricks.accounts ]
    }
  }
}

resource "databricks_metastore" "this" {
  provider      = databricks.accounts
  name          = var.databricks_metastore_name
  owner         = var.databricks_unity_admin_group
  region        = var.aws_region
  storage_root  = var.databricks_storage_root
  force_destroy = true
}

resource "databricks_metastore_assignment" "this" {
  provider             = databricks.accounts
  for_each             = toset(var.databricks_workspace_ids)
  workspace_id         = each.key
  metastore_id         = databricks_metastore.this.id
  default_catalog_name = var.databricks_catalog_name
}