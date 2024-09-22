/* AWS Workspace Module

Deploy AWS Infra for Databricks Workspace
*/

terraform{
  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = "~> 1.39.0"
    }
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.15.0"
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS PROVIDER
##
## Configures the AWS provider with authentication session details.
##
## Parameters:
## - `alias`: An alias for the provider.
## - `access_key`: The AWS access key.
## - `secret_key`: The AWS secret key.
## - `profile`: The AWS CLI profile.
## - `region`: The AWS region.
## ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  alias      = "auth_session"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  // An ambiguous error is thrown without declaring a profile
  // However, access_key/secret_key override profile credentials
  profile    = var.aws_cli_profile
  region     = var.aws_region
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS CALLER IDENTITY DATA
##
## Retrieves the AWS caller identity using the configured authentication session.
## ---------------------------------------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {
  provider = aws.auth_session
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS S3 BUCKET RAW DATA
##
## Retrieves information about an existing S3 bucket named "raw" using the configured authentication session.
##
## Parameters:
## - `bucket`: The name of the S3 bucket to retrieve information about.
## ---------------------------------------------------------------------------------------------------------------------
data "aws_s3_bucket" "raw" {
  provider = aws.auth_session

  bucket = var.aws_raw_bucket_name
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS S3 BUCKET STANDARD DATA
##
## Retrieves information about an existing S3 bucket named "standard" using the configured authentication session.
##
## Parameters:
## - `bucket`: The name of the S3 bucket to retrieve information about.
## ---------------------------------------------------------------------------------------------------------------------
data "aws_s3_bucket" "standard" {
  provider = aws.auth_session

  bucket = var.aws_standard_bucket_name
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
  prefix             = var.resource_prefix != null ? var.resource_prefix : "${local.program}-${local.project}-${random_string.this.id}"
  client_id_name     = var.aws_access_key_name != null ? var.aws_access_key_name : "${local.prefix}-sp-client-id"
  client_secret_name = var.aws_access_key_name != null ? var.aws_access_key_name : "${local.prefix}-sp-client-secret"
  
  tags             = merge(var.tags, {
    program = local.program
    project = local.project
    env     = "dev"
  })
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS STAGE BUCKET MODULE
##
## Deploys an AWS S3 bucket for Staging Data.
##
## Parameters:
## - `bucket_name`: The name of the S3 bucket to create.
##
## Providers: 
## - `aws.auth_session`: The AWS Authentication Session provider.
## ---------------------------------------------------------------------------------------------------------------------
module "aws_stage_bucket" {
  source      = "github.com/rethinkr-hub/py-superhero-dataflow.git//batch/serverless_functions/aws/modules/superhero_buckets"
  bucket_name = "${local.prefix}-stage"

  providers = {
    aws.auth_session = aws.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS OUTPUT BUCKET MODULE
##
## Deploys an AWS S3 bucket for Output Data.
##
## Parameters:
## - `bucket_name`: The name of the S3 bucket to create.
##
## Providers: 
## - `aws.auth_session`: The AWS Authentication Session provider.
## ---------------------------------------------------------------------------------------------------------------------
module "aws_output_bucket" {
  source                   = "github.com/rethinkr-hub/py-superhero-dataflow.git//batch/serverless_functions/aws/modules/superhero_buckets"
  bucket_name              = "${local.prefix}-output"
  
  providers = {
    aws.auth_session = aws.auth_session
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS SECURITY GROUP MODULE
##
## Deploys security groups for Access Control to AWS S3 Buckets.
##
## Parameters:
## - `contributor_user`: The ID of the user contributing to the security group.
## - `group_prefix`: The prefix for the group.
## - `resource_arns`: The ARNs of the resources.
##
## Providers: 
## - `aws.auth_session`: The AWS Authentication Session provider.
## ---------------------------------------------------------------------------------------------------------------------
module "aws_security_groups" {
  source           = "github.com/rethinkr-hub/py-superhero-dataflow.git//batch/serverless_functions/aws/modules/superhero_security_groups"
  depends_on       = [ 
    module.aws_stage_bucket,
    module.aws_output_bucket
  ]

  contributor_user = data.aws_caller_identity.current.user_id
  group_prefix     = local.prefix

  resource_arns    = [
    data.aws_s3_bucket.raw.arn,
    "${data.aws_s3_bucket.raw.arn}/*",
    data.aws_s3_bucket.standard.arn,
    "${data.aws_s3_bucket.standard.arn}/*",
    module.aws_stage_bucket.bucket_arn,
    "${module.aws_stage_bucket.bucket_arn}/*",
    module.aws_output_bucket.bucket_arn,
    "${module.aws_output_bucket.bucket_arn}/*",
  ]
  
  providers = {
    aws.auth_session = aws.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS KMS KEY MODULE
##
## Deploys an AWS Key Management Service (KMS) key.
##
## Parameters:
## - `kms_key_name`: The name of the KMS key.
##
## Providers: 
## - `aws.auth_session`: The AWS Authentication Session provider.
## ---------------------------------------------------------------------------------------------------------------------
module "aws_kms_key" {
  source           = "./modules/aws_kms_key"
  kms_key_name     = "${local.prefix}-kms-key"

  providers = {
    aws.auth_session = aws.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AWS SECRET CLIENT ID MODULE
##
## Deploys an AWS Secret Manager secret for the Databricks Service Principal Client ID.
##
## Parameters:
## - `kms_key_id`: The ID of the AWS KMS key used to encrypt the secret.
## - `secret_name`: The name of the secret.
## - `secret_description`: The description of the secret.
## - `secret_value`: The value of the secret (in this case, the AWS access key).
## - `administrator_arn`: The ARN of the AWS IAM administrator.
##
## Providers: 
## - `aws.auth_session`: The AWS Authentication Session provider.
## ---------------------------------------------------------------------------------------------------------------------
module "aws_secret_client_id" {
  source             = "./modules/aws_secret"
  
  kms_key_id         = module.aws_kms_key.kms_key_id
  secret_name        = local.client_id_name
  secret_description = "Databricks Service Principal Client ID to Read Blobs"
  secret_value       = var.aws_access_key
  administrator_arn  = data.aws_caller_identity.current.arn

  providers = {
    aws.auth_session = aws.auth_session
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS SECRET CLIENT SECRET MODULE
##
## Deploys an AWS Secret Manager secret for the Databricks Service Principal Client Secret.
##
## Parameters:
## - `kms_key_id`: The ID of the AWS KMS key used to encrypt the secret.
## - `secret_name`: The name of the secret.
## - `secret_description`: The description of the secret.
## - `secret_value`: The value of the secret (in this case, the AWS access key).
## - `administrator_arn`: The ARN of the AWS IAM administrator.
##
## Providers: 
## - `aws.auth_session`: The AWS Authentication Session provider.
## ---------------------------------------------------------------------------------------------------------------------
module "aws_secret_client_secret" {
  source             = "./modules/aws_secret"
  
  kms_key_id         = module.aws_kms_key.kms_key_id
  secret_name        = local.client_secret_name
  secret_description = "Databricks Service Principal Client Secret to Read Blobs"
  secret_value       = var.aws_secret_key
  administrator_arn  = data.aws_caller_identity.current.arn

  providers = {
    aws.auth_session = aws.auth_session
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS PROVIDER
##
## Configures the Databricks provider with authentication session to Databricks Accounts Portal.
##
## Parameters:
## - `alias`: Provdier Alias to Databricks Accounts
## - `profile`: The Databricks CLI profile used for authentication.
## ---------------------------------------------------------------------------------------------------------------------
provider "databricks" {
  alias   = "accounts"
  profile = var.databricks_cli_profile
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS BUCKET MODULE
##
## This module creates a bucket for Databricks workspace.
##
## Parameters:
## - `databricks_account_id`: The ID of the Databricks account.
## - `aws_bucket_name`: The name of the AWS bucket.
## - `tags`: Tags to apply to the bucket.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## - `databricks.accounts`: The Databricks provider for managing accounts.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_bucket" {
  source                = "./modules/databricks_bucket"
  databricks_account_id = var.databricks_account_id
  aws_bucket_name       = "${local.prefix}-databricks-workspace"
  tags                  = var.tags

  providers = {
    aws.auth_session = aws.auth_session
    databricks.accounts = databricks.accounts
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS IAM ROLE MODULE
##
## This module creates an IAM role for Databricks workspace.
##
## Parameters:
## - `databricks_account_id`: The ID of the Databricks account.
## - `aws_iam_role_name`: The name of the AWS IAM role.
## - `tags`: Tags to apply to the IAM role.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## - `databricks.accounts`: The Databricks provider for managing accounts.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_iam_role" {
  source                = "./modules/databricks_iam_role"
  databricks_account_id = var.databricks_account_id
  aws_iam_role_name     = "${local.prefix}-databricks-workspace"
  tags                  = var.tags

  providers = {
    aws.auth_session = aws.auth_session
    databricks.accounts = databricks.accounts
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS VPC MODULE
##
## This module creates a VPC for Databricks workspace.
##
## Parameters:
## - `databricks_account_id`: The ID of the Databricks account.
## - `aws_vpc_name`: The name of the AWS VPC.
## - `tags`: Tags to apply to the VPC.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## - `databricks.accounts`: The Databricks provider for managing accounts.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_vpc" {
  source                = "./modules/databricks_vpc"
  databricks_account_id = var.databricks_account_id
  aws_vpc_name          = "${local.prefix}-databricks-workspace"
  tags                  = var.tags

  providers = {
    aws.auth_session = aws.auth_session
    databricks.accounts = databricks.accounts
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS MWS WORKSPACES RESOURCE
##
## This resource creates a Databricks MultiWorkspace Services (MWS) workspace.
##
## Parameters:
## - `account_id`: The ID of the Databricks account.
## - `aws_region`: The AWS region.
## - `workspace_name`: The name of the workspace.
## - `credentials_id`: The ID of the IAM role for credentials.
## - `storage_configuration_id`: The ID of the storage configuration.
## - `network_id`: The ID of the network.
##
## Providers:
## - `databricks.accounts`: The Databricks provider for managing accounts.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_mws_workspaces" "this" {
  provider       = databricks.accounts
  account_id     = var.databricks_account_id
  aws_region     = var.aws_region
  workspace_name = "${local.prefix}-databricks-workspace"

  credentials_id           = module.databricks_iam_role.credentials_id
  storage_configuration_id = module.databricks_bucket.storage_configuration_id
  network_id               = module.databricks_vpc.network_id

  token {
    comment = "Terraform"
  }
}
