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
  cloud   = "aws"
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
## - `aws_iam_role`: The IAM role ARN used by Databricks to access AWS services.
##
## Providers:
## - `databricks.workspace`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_storage_credential" "this" {
  provider = databricks.workspace
  name     = local.credential_name
  databricks_gcp_service_account {}
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS EXTERNAL LOCATION RESOURCE
##
## This resource defines an external location in Databricks.
##
## Parameters:
## - `name`: The name of the external location.
## - `url`: The URL of the external location.
## - `credential_name`: The name of the storage credential associated with the external location.
##
## Providers:
## - `databricks.workspace`: The Databricks provider.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_external_location" "this" {
  provider        = databricks.workspace
  name            = "${local.credential_name}-external-location"
  url             = "gcs://${var.databricks_metastore_bucket_name}/metastore" #Same as databricks_metastore storage_root parameter
  credential_name = databricks_storage_credential.this.id
}
