terraform {
  required_providers {
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.39.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.15.0"
    }
  }
}

terraform {
  backend "s3" {}
}

## ---------------------------------------------------------------------------------------------------------------------
## AWS PROVIDER
##
## Configures the AWS provider with CLI Credentials.
##
## Parameters:
## - `alias`: An alias for the provider.
## - `profile`: The AWS CLI profile.
## - `region`: The AWS region.
## ---------------------------------------------------------------------------------------------------------------------
provider "aws" {
  alias   = "accountgen"
  profile = var.aws_cli_profile
  region  = var.aws_region
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
  secret_scope        = var.databricks_secret_scope != null ? var.databricks_secret_scope : "${upper(local.cloud)}"
  prefix              = var.resource_prefix != null ? var.resource_prefix : "${local.program}-${local.project}-${random_string.this.id}"
  iam_roles = distinct(concat(var.aws_iam_bootstrap, [
    "iam:*",
    "secretsmanager:*",
    "ec2:*",
    "kms:*",
    "s3:*"
  ]))

  maven_libraries = distinct(concat(var.databricks_cluster_libraries, [
    "org.apache.hadoop:hadoop-aws:3.3.4",
    "com.amazonaws:aws-java-sdk:1.12.552"
  ]))

  tags    = merge(var.tags, {
    program = local.program
    project = local.project
    env     = "dev"
  })
}

/* Create and Authenticate Service Account Session

The Service Account Auth Module will authenticate with AWS using
the IP Bound Service Account to request Access Tokens, and
create new short-live Service Accounts to Deploy/Destroy our
Superhero Simulator Dataflow
*/
module "service_account_auth" {
  source                      = "github.com/rethinkr-hub/py-superhero-dataflow.git//batch/serverless_functions/aws/modules/service_account_auth"
  new_service_account_name    = "${local.prefix}-service-account"
  bootstrap_iam_roles         = local.iam_roles
  
  providers = {
    aws.accountgen = aws.accountgen
  }
}

module "databricks_aws_workspace" {
  source                   = "../modules/aws_workspace"
  databricks_account_id    = var.databricks_account_id
  databricks_cli_profile   = var.databricks_cli_profile
  aws_cli_profile          = var.aws_cli_profile
  aws_access_key           = module.service_account_auth.access_id
  aws_secret_key           = module.service_account_auth.access_token
  aws_region               = var.aws_region
  aws_raw_bucket_name      = var.aws_raw_bucket
  aws_standard_bucket_name = var.aws_standard_bucket
  tags                     = local.tags
}

module "databricks_aws_unity_catalog" {
  source                                     = "../modules/aws_unity_catalog"
  databricks_account_id                      = var.databricks_account_id
  databricks_workspace_id                    = module.databricks_aws_workspace.databricks_workspace_id
  databricks_host                            = module.databricks_aws_workspace.databricks_host
  databricks_token                           = module.databricks_aws_workspace.databricks_token
  databricks_administrator                   = var.databricks_administrator
  databricks_cli_profile                     = var.databricks_cli_profile
  aws_cli_profile                            = var.aws_cli_profile
  aws_access_key                             = module.service_account_auth.access_id
  aws_secret_key                             = module.service_account_auth.access_token
  aws_region                                 = var.aws_region
  tags                                       = local.tags
}

provider "databricks" {
  alias = "workspace"
  host  = module.databricks_aws_workspace.databricks_host
  token = module.databricks_aws_workspace.databricks_token
}

module "databricks_secret_scope" {
  source       = "../modules/databricks_secret_scope"
  depends_on   = [ module.databricks_aws_unity_catalog ]

  secret_scope = local.secret_scope

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_service_account_key_name_secret" {
  source          = "../modules/databricks_secret"
  depends_on      = [ module.databricks_aws_unity_catalog ]

  # Define the secret scope ID where the secret will be stored
  secret_scope_id = module.databricks_secret_scope.databricks_secret_scope_id
  
  # Define the name of the secret
  secret_name     = module.databricks_aws_workspace.aws_client_id_secret_name
  
  # Define the data of the secret (client ID of the Azure service principal)
  secret_data     = module.service_account_auth.access_id
  
  # Define the provider for the module
  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_service_account_key_data_secret" {
  source          = "../modules/databricks_secret"
  depends_on      = [ module.databricks_aws_unity_catalog ]
  # Define the secret scope ID where the secret will be stored
  secret_scope_id = module.databricks_secret_scope.databricks_secret_scope_id

  # Define the name of the secret
  secret_name     = module.databricks_aws_workspace.aws_client_secret_secret_name

  # Define the data of the secret (client Secret of the Azure service principal)
  secret_data     = module.service_account_auth.access_token

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_token" {
  source = "../modules/databricks_pat_token"

  # Define the provider for the module
  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_instance_pool_driver" {
  source                     = "../modules/databricks_instace_pool"
  depends_on                 = [ module.databricks_aws_unity_catalog ]

  # Define the name and maximum capacity of the instance pool
  instance_pool_name         = "${local.prefix}-driver-pool"
  instance_pool_max_capacity = var.databricks_instance_pool_driver_max_capacity

  # Define the provider for the module
  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_instance_pool_node" {
  source                     = "../modules/databricks_instace_pool"
  depends_on                 = [ module.databricks_aws_unity_catalog ]

  # Define the name and maximum capacity of the instance pool
  instance_pool_name         = "${local.prefix}-node-pool"
  instance_pool_max_capacity = var.databricks_instance_pool_node_max_capacity

  # Define the provider for the module
  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_cluster_policy" {
  source              = "../modules/databricks_cluster_policy"
  depends_on          = [module.databricks_aws_unity_catalog]

  # Specify the name of the cluster policy
  cluster_policy_name = "${local.prefix}-cluster-policy"

  # Specify the name of the engineer group to associate the policy with
  group_name          = module.databricks_aws_unity_catalog.databricks_user_group
  data_security_mode  = var.databricks_cluster_data_security_mode

  # Define the provider for the module
  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_cluster" {
  source                  = "../modules/databricks_cluster"
  depends_on              = [module.databricks_cluster_policy]

  # Specify the name of the Databricks cluster
  cluster_name            = "${local.prefix}-cluster"

  # Specify the instance pool IDs for nodes and driver
  node_instance_pool_id   = module.databricks_instance_pool_node.instance_pool_id
  driver_instance_pool_id = module.databricks_instance_pool_driver.instance_pool_id

  # Specify the name and ID of the cluster policy
  cluster_policy_name     = module.databricks_cluster_policy.cluster_policy_name
  cluster_policy_id       = module.databricks_cluster_policy.cluster_policy_id

  # Define Spark environment variables
  spark_env_variable      = {
    "CLOUD_PROVIDER": upper(local.cloud),
    "RAW_DIR": "s3://${module.databricks_aws_workspace.aws_raw_bucket_name}/raw",
    "STANDARD_DIR": "s3://${module.databricks_aws_workspace.aws_standard_bucket_name}/standard",
    "STAGE_DIR": "s3://${module.databricks_aws_workspace.aws_stage_bucket_name}/stage",
    "OUTPUT_DIR": "s3://${module.databricks_aws_workspace.aws_output_bucket_name}/output",
    "SERVICE_ACCOUNT_CLIENT_ID": "spark.hadoop.fs.s3a.access.key",
    "SERVICE_ACCOUNT_CLIENT_SECRET": "spark.hadoop.fs.s3a.secret.key"
  }

  # Define Spark configuration variables
  spark_conf_variable     = {
    "spark.hadoop.fs.s3a.endpoint": "s3.amazonaws.com",
    "spark.hadoop.fs.s3a.access.key": "{{secrets/${module.databricks_secret_scope.databricks_secret_scope_id}/${module.databricks_service_account_key_name_secret.databricks_secret_name}}}",
    "spark.hadoop.fs.s3a.secret.key": "{{secrets/${module.databricks_secret_scope.databricks_secret_scope_id}/${module.databricks_service_account_key_data_secret.databricks_secret_name}}}",
    "spark.hadoop.fs.s3a.aws.credentials.provider": "org.apache.hadoop.fs.s3a.BasicAWSCredentialsProvider",
    "spark.hadoop.fs.s3a.server-side-encryption-algorithm": "SSE-KMS",
    "spark.databricks.driver.strace.enabled": "true"
  }

  # Define Maven libraries for the cluster
  maven_libraries         = local.maven_libraries

  # Define the provider for the module
  providers = {
    databricks.workspace = databricks.workspace
  }
}