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
  prefix          = "${local.program}-${local.project}-${random_string.this.id}"
  credential_name = var.databricks_storage_credential_name != null ? var.databricks_storage_credential_name : "${local.prefix}-metastore-storage-credential"
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS STORAGE CREDENTIAL RESOURCE
##
## This resource defines a storage credential in Databricks.
##
## Parameters:
## - `name`: The name of the storage credential.
## - `azure_managed_identity`: Configuration for Azure managed identity, including the access connector ID.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_storage_credential" "this" {
  provider = databricks.workspace
  name     = local.credential_name
  
  azure_managed_identity {
    access_connector_id = var.databricks_access_connector_id
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS EXTERNAL LOCATION RESOURCE
##
## This resource defines an external location in Databricks.
##
## Parameters:
## - `name`: The name of the external location.
## - `url`: The URL of the external location.
## - `credential_name`: The ID of the storage credential associated with this external location.
## ---------------------------------------------------------------------------------------------------------------------
/*
resource "databricks_external_location" "this" {
  provider        = databricks.workspace
  name            = "${local.credential_name}-external-location"
  url             = var.databricks_external_location_url
  credential_name = databricks_storage_credential.this.id
}
*/