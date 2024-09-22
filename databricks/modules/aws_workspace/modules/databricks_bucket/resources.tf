/* Databricks S3 Bucket Deployment */

terraform{
  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [ databricks.accounts, ]
    }
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
  cloud   = "aws"
  program = "spark-databricks"
  project = "datasim"
}

locals  {
  prefix      = "${local.program}-${local.project}-${random_string.this.id}"
  bucket_name = var.aws_bucket_name != null ? var.aws_bucket_name : "${local.prefix}-databricks-workspace"
  tags        = merge(var.tags, {
    program = local.program
    project = local.project
    env     = "dev"
  })
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS S3 BUCKET RESOURCE
##
## This resource creates an S3 bucket with the specified configuration.
##
## Parameters:
## - `bucket`: The name of the bucket.
## - `force_destroy`: A boolean that indicates all objects should be deleted from the bucket so that the bucket can be
##   destroyed without error.
## - `tags`: A mapping of tags to assign to the bucket.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "this" {
  provider      = aws.auth_session
  bucket        = local.bucket_name
  force_destroy = true
  tags          = local.tags
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS S3 BUCKET SERVER SIDE ENCRYPTION CONFIGURATION RESOURCE
##
## This resource configures server-side encryption for the specified S3 bucket using AES256 encryption algorithm.
##
## Parameters:
## - `bucket`: The name of the bucket for which the server-side encryption configuration is applied.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  provider = aws.auth_session
  bucket   = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS S3 BUCKET PUBLIC ACCESS BLOCK RESOURCE
##
## This resource blocks public access to the specified S3 bucket.
##
## Parameters:
## - `bucket`: The ID of the bucket for which public access is blocked.
## - `block_public_acls`: Whether to block public ACLs for the bucket.
## - `block_public_policy`: Whether to block public policies for the bucket.
## - `ignore_public_acls`: Whether to ignore public ACLs when determining public access.
## - `restrict_public_buckets`: Whether to restrict public bucket policies for the bucket.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "this" {
  provider                = aws.auth_session
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.this]
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS AWS BUCKET POLICY DATA SOURCE
##
## This data source retrieves the policy of the specified AWS S3 bucket.
##
## Parameters:
## - `bucket`: The name of the AWS S3 bucket.
##
## Providers:
## - `databricks.accounts`: The Databricks provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
data "databricks_aws_bucket_policy" "this" {
  provider = databricks.accounts
  bucket   = aws_s3_bucket.this.bucket
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS S3 BUCKET POLICY RESOURCE
##
## This resource applies the policy obtained from the Databricks AWS bucket policy data source to the specified AWS S3 bucket.
##
## Parameters:
## - `bucket`: The name of the AWS S3 bucket.
## - `policy`: The policy obtained from the Databricks AWS bucket policy data source.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "root_bucket_policy" {
  provider   = aws.auth_session
  bucket     = aws_s3_bucket.this.id
  policy     = data.databricks_aws_bucket_policy.this.json
  depends_on = [aws_s3_bucket_public_access_block.this]
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS S3 BUCKET VERSIONING RESOURCE
##
## This resource configures versioning for the specified AWS S3 bucket.
##
## Parameters:
## - `bucket`: The name of the AWS S3 bucket.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_versioning" "this" {
  provider = aws.auth_session
  bucket   = aws_s3_bucket.this.id
  
  versioning_configuration {
    status = "Disabled"
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS MULTIWORKSPACE SERVICES STORAGE CONFIGURATION RESOURCE
##
## This resource configures a storage configuration for Databricks MultiWorkspace Services.
##
## Parameters:
## - `account_id`: The Databricks account ID.
## - `bucket_name`: The name of the AWS S3 bucket.
## - `storage_configuration_name`: The name of the storage configuration.
##
## Providers:
## - `databricks.accounts`: The Databricks provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_mws_storage_configurations" "this" {
  provider                   = databricks.accounts
  account_id                 = var.databricks_account_id
  bucket_name                = aws_s3_bucket.this.bucket
  storage_configuration_name = "${local.bucket_name}-storage"
}
