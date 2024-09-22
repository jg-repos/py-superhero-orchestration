terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = "~> 1.39.0"
      configuration_aliases = [ databricks.workspace ]
    }
  }
}

resource "databricks_external_location" "this" {
  provider        = databricks.workspace
  name            = var.databricks_external_location_name
  url             = "s3://${var.aws_external_bucket_name}/some"
  credential_name = var.databricks_storage_credential_id
}

resource "databricks_catalog" "this" {
  provider     = databricks.workspace
  storage_root = "s3://${var.aws_external_bucket_name}/some"
  name         = "sandbox"
  comment      = "this catalog is managed by terraform"
  properties = {
    purpose = "testing"
  }
}

resource "databricks_grants" "this" {
  provider = databricks.workspace
  catalog  = databricks_catalog.this.name
  grant {
    principal  = "Data Scientists"
    privileges = ["USE_CATALOG", "CREATE"]
  }
  grant {
    principal  = "Data Engineers"
    privileges = ["USE_CATALOG"]
  }
}