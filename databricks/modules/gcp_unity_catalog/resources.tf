terraform{
  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = "~> 1.39.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "4.47.0"
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
  prefix             = var.resource_prefix != null ? var.resource_prefix : "${local.program}-${local.project}-${random_string.this.id}"
  unity_catalog_name   = var.databricks_unity_catalog_name != null ? var.databricks_unity_catalog_name : "${local.prefix}-databricks-unity-catalog"
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE PROVIDER
##
## This provider block creates an alias for the Google provider to use the access token and project ID provided.
##
## Parameters:
## - None
##
## Providers:
## - `google.auth_session`: Alias for authenticating with Google Cloud Platform.
## ---------------------------------------------------------------------------------------------------------------------
provider "google" {
  alias        = "auth_session"
  access_token = var.gcp_access_token
  project      = var.gcp_project_id
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS PROVIDER CONFIGURATION
##
## The Databricks provider configuration is used to authenticate with the Databricks API using a specific profile.
##
## Parameters:
## - `alias`: Alias for the provider, used to differentiate between multiple provider configurations.
## - `profile`: Name of the Databricks CLI profile to use for authentication.
## ---------------------------------------------------------------------------------------------------------------------
provider "databricks" {
  alias   = "accounts"
  profile = var.databricks_cli_profile
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS PROVIDER CONFIGURATION
##
## The Databricks provider configuration is used to authenticate with a Databricks workspace using an access token.
##
## Parameters:
## - `alias`: Alias for the provider, used to differentiate between multiple provider configurations.
## - `host`: Hostname of the Databricks workspace.
## - `token`: Access token for authenticating with the Databricks workspace.
## ---------------------------------------------------------------------------------------------------------------------
provider "databricks" {
  alias = "workspace"
  host  = var.databricks_host
  token = var.databricks_token
}


## ---------------------------------------------------------------------------------------------------------------------
## GCP METASTORE BUCKET MODULE
##
## This module creates a GCS bucket for Databricks metastore storage.
##
## Parameters:
## - `databricks_storage_credential_name`: The name of the Databricks storage credential.
##
## Providers:
## - `aws.auth_session`: The AWS provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
module "gcp_metastore_bucket" {
  source                             = "./modules/gcp_metastore_bucket"
  databricks_storage_credential_name = "${local.unity_catalog_name}-metastore-bucket"
  gcp_region                         = var.gcp_region

  providers = {
    google.auth_session = google.auth_session
  }
}



## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS ADMIN GROUP MODULE
##
## This module creates an admin group in Databricks.
##
## Parameters:
## - `group_name`: The name of the admin group.
## - `allow_cluster_create`: Whether the group is allowed to create clusters.
## - `allow_databricks_sql_access`: Whether the group is allowed to access Databricks SQL.
## - `allow_instance_pool_create`: Whether the group is allowed to create instance pools.
##
## Providers:
## - `databricks.workspace`: The Databricks provider for workspace management.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_admin_group" {
  source                      = "../databricks_group"
  group_name                  = "${local.unity_catalog_name}-admin-group"
  allow_cluster_create        = true
  allow_databricks_sql_access = true
  allow_instance_pool_create  = true

  providers = {
    databricks.workspace = databricks.accounts
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS USER GROUP MODULE
##
## This module creates a user group in Databricks.
##
## Parameters:
## - `group_name`: The name of the user group.
## - `allow_databricks_sql_access`: Whether the group is allowed to access Databricks SQL.
##
## Providers:
## - `databricks.workspace`: The Databricks provider for workspace management.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_user_group" {
  source                      = "../databricks_group"
  group_name                  = "${local.unity_catalog_name}-user-group"
  allow_databricks_sql_access = true

  providers = {
    databricks.workspace = databricks.accounts
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS METASTORE RESOURCE
##
## This resource defines a metastore in Databricks.
##
## Parameters:
## - `name`: The name of the metastore.
## - `region`: The region for the metastore.
## - `owner`: The owner of the metastore.
## - `storage_root`: The storage root for the metastore.
## - `force_destroy`: Whether to force destroy the metastore.
##
## Providers:
## - `databricks.accounts`: The Databricks provider for account management.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_metastore" "this" {
    provider      = databricks.accounts
    name          = "${local.unity_catalog_name}-metastore"
    region        = var.gcp_region
    owner         = module.databricks_admin_group.databricks_group_name
    storage_root  = module.databricks_external_locations.databricks_external_location_url
    force_destroy = true
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS METASTORE ASSIGNMENT RESOURCE
##
## This resource assigns a metastore to a Databricks workspace.
##
## Parameters:
## - `workspace_id`: The ID of the Databricks workspace.
## - `metastore_id`: The ID of the metastore.
## - `default_catalog_name`: The default catalog name for the metastore assignment.
##
## Providers:
## - `databricks.accounts`: The Databricks provider for account management.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_metastore_assignment" "this" {
  provider             = databricks.accounts
  depends_on           = [ databricks_metastore.this ]
  workspace_id         = var.databricks_workspace_id
  metastore_id         = databricks_metastore.this.id
  default_catalog_name = var.databricks_default_catalog_name
}


## ---------------------------------------------------------------------------------------------------------------------
## TIME_SLEEP RESOURCE
##
## This resource adds a delay to wait for the workspace to enable identity federation.
##
## Parameters:
## - `create_duration`: The duration to wait before completing module databricks_metastore_user_management.
##
## Dependencies:
## - `databricks_metastore_assignment.this`: The Databricks Metastore Assignment resource.
## ---------------------------------------------------------------------------------------------------------------------
resource "time_sleep" "wait_for_permission_apis" {
  depends_on = [
    databricks_metastore_assignment.this
  ]
  create_duration = "300s"
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS METASTORE USER MANAGEMENT MODULE
##
## This module manages users for the Databricks metastore.
##
## Parameters:
## - `databricks_account_id`: The ID of the Databricks account.
## - `databricks_workspace_id`: The ID of the Databricks workspace.
## - `databricks_administrator`: The administrator role for Databricks.
## - `databricks_administrator_group`: The name of the Databricks administrator group.
## - `databricks_user_group`: The name of the Databricks user group.
##
## Providers:
## - `databricks.accounts`: The Databricks provider for account management.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_metastore_user_management" {
  source                                     = "./modules/databricks_metastore_users"
  depends_on                                 = [ 
    time_sleep.wait_for_permission_apis,
    module.databricks_admin_group,
    module.databricks_user_group 
  ]

  databricks_account_id                      = var.databricks_account_id
  databricks_workspace_id                    = var.databricks_workspace_id
  databricks_administrator                   = var.databricks_administrator
  databricks_administrator_group             = module.databricks_admin_group.databricks_group_name
  databricks_user_group                      = module.databricks_user_group.databricks_group_name
  gcp_metastore_bucket_name                  = module.gcp_metastore_bucket.databricks_metastore_bucket_name
  gcp_service_acccount                       = databricks_metastore_data_access.first.databricks_gcp_service_account[0].email

  providers = {
    databricks.accounts = databricks.accounts
    google.auth_session = google.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS EXTERNAL LOCATIONS MODULE
##
## This module configures external locations for Databricks.
##
## Parameters:
## - `databricks_storage_credential_name`: The name of the Databricks storage credential.
## - `databricks_metastore_bucket_id`: The ID of the Databricks metastore bucket.
## - `databricks_metastore_cross_account_policy_arn`: The ARN of the Databricks metastore cross-account policy.
##
## Providers:
## - `databricks.workspace`: The Databricks provider for workspace management.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_external_locations" {
  source                         = "./modules/databricks_external_location"
  
  databricks_storage_credential_name              = local.unity_catalog_name
  databricks_metastore_bucket_name                = module.gcp_metastore_bucket.databricks_metastore_bucket_name

  providers = {
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS METASTORE DATA ACCESS RESOURCE
##
## This resource configures data access for Databricks Metastore.
##
## Parameters:
## - `metastore_id`: The ID of the Databricks Metastore.
## - `name`: The name of the data access policy.
## - `aws_iam_role`: Configuration for the AWS IAM role.
## - `is_default`: Specifies if this is the default data access policy.
##
## Providers:
## - `databricks.workspace`: The Databricks provider for workspace.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_metastore_data_access" "this" {
  provider     = databricks.workspace
  metastore_id = databricks_metastore.this.id
  name         = "${local.unity_catalog_name}-metastore-data-access"
  is_default = true
}


/*
resource "databricks_grants" "this" {
  provider   = databricks.accounts
  depends_on = [ module.databricks_metastore_user_management ]
  metastore  = databricks_metastore.this.id
  grant {
    principal  = var.databricks_administrator_group
    privileges = ["CREATE_CATALOG", "CREATE_EXTERNAL_LOCATION"]
  }
}

resource "databricks_catalog" "this" {
  provider     = databricks.workspace
  depends_on   = [ databricks_metastore_data_access.this ]
  metastore_id = databricks_metastore.this.metastore_id
  name         = "datasim-superhero-databricks-unity-catalog"
  comment      = "This catalog is managed by terraform"
  properties   = {
    purpose = "Demoing catalog creation and management using Terraform"
  }

  force_destroy = true
}

*/