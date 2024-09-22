terraform{
  required_providers {
    aws = {
      source = "hashicorp/aws"
      configuration_aliases = [ aws.auth_session, ]
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
  cloud   = "gcp"
  program = "spark-databricks"
  project = "datasim"
}

locals  {
  prefix          = "${local.program}-${local.project}-${random_string.this.id}"
  credential_name = var.databricks_storage_credential_name != null ? var.databricks_storage_credential_name : "${local.prefix}-metastore-storage-credential"
}

## ---------------------------------------------------------------------------------------------------------------------
## GCP GCS BUCKET RESOURCE
##
## This resource creates a GCP GCS bucket.
##
## Parameters:
## - `bucket`: The name of the GCS bucket.
## - `force_destroy`: A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed.
##
## Providers:
## - `google.auth_session`: The GCP provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_storage_bucket" "this" {
  name          = "${credential_name}-metastore-bucket"
  location      = var.gcp_region
  force_destroy = true
}


