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
  cloud   = "aws"
  program = "spark-databricks"
  project = "datasim"
}

locals  {
  prefix          = "${local.program}-${local.project}-${random_string.this.id}"
  credential_name = var.databricks_storage_credential_name != null ? var.databricks_storage_credential_name : "${local.prefix}-metastore-storage-credential"
  tags            = merge(var.tags, {
    program = local.program
    project = local.project
    env     = "dev"
  })
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS S3 BUCKET RESOURCE
##
## This resource creates an AWS S3 bucket.
##
## Parameters:
## - `bucket`: The name of the S3 bucket.
## - `force_destroy`: A boolean that indicates all objects should be deleted from the bucket so that the bucket can be destroyed.
## - `tags`: A mapping of tags to assign to the bucket.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket" "this" {
    provider      = aws.auth_session
    bucket        = local.credential_name
    force_destroy = true
    tags          = local.tags
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS S3 BUCKET VERSIONING RESOURCE
##
## This resource configures versioning for an AWS S3 bucket.
##
## Parameters:
## - `bucket`: The name of the S3 bucket.
## - `status`: The versioning status. Valid values are "Enabled" or "Suspended".
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
## AWS S3 BUCKET SERVER-SIDE ENCRYPTION CONFIGURATION RESOURCE
##
## This resource configures server-side encryption for an AWS S3 bucket.
##
## Parameters:
## - `bucket`: The name of the S3 bucket.
## - `sse_algorithm`: The server-side encryption algorithm. This should be "AES256" for AES-256 encryption.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "root_storage_bucket" {
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
## This resource configures public access blocking for an AWS S3 bucket.
##
## Parameters:
## - `bucket`: The name of the S3 bucket.
## - `block_public_acls`: Whether to block public ACLs for the bucket. Set to true to block.
## - `block_public_policy`: Whether to block public bucket policies for the bucket. Set to true to block.
## - `ignore_public_acls`: Whether to ignore public ACLs for the bucket. Set to true to ignore.
## - `restrict_public_buckets`: Whether to restrict public bucket policies for the bucket. Set to true to restrict.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "aws_s3_bucket_public_access_block" "metastore" {
    provider                = aws.auth_session
    bucket                  = aws_s3_bucket.this.id
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
    depends_on              = [aws_s3_bucket.this]
}
