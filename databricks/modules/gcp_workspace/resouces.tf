terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = "1.25.0"
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
  client_key_name    = "${local.prefix}-service-account-key"
  client_secret_name = "${local.prefix}-service-account-secret"
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
## DATABRICKS SERVICE ACCOUNT MODULE
##
## This module creates a service account for Databricks.
##
## Parameters:
## - `gcp_project_id`: The ID of the Google Cloud Platform (GCP) project.
## - `gcp_impersonate_user_email`: The email address of the user to impersonate.
## - `service_account_email`: The email address of the service account.
## - `service_account_name`: The name of the service account.
##
## Providers:
## - `google.auth_session`: The Google Cloud provider.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_service_account" {
  source                 = "./modules/databricks_service_account"
  depends_on             = [ module.service_account_auth ]

  gcp_project_id             = var.gcp_project_id
  gcp_impersonate_user_email = var.gcp_impersonate_user_email
  service_account_email      = module.service_account_auth.service_account_email
  service_account_name       = module.service_account_auth.service_account_name
  
  providers = {
    google.auth_session = google.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SERVICE ACCOUNT KEY NAME MODULE
##
## This module manages the secret key name for the Databricks service account.
##
## Parameters:
## - `gcp_region`: The region for Google Cloud resources.
## - `secret_name`: The name of the secret.
## - `secret_data`: The secret data.
##
## Providers:
## - `google.auth_session`: The Google Cloud provider.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_service_account_key_name" {
  source      = "./modules/databricks_secret_manager"
  depends_on  = [ module.databricks_service_account ]

  gcp_region    = var.gcp_region
  secret_name   = local.client_key_name
  secret_data   = module.databricks_service_account.gcp_databricks_service_account_key_name

  providers = {
    google.auth_session = google.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SERVICE ACCOUNT KEY SECRET MODULE
##
## This module manages the secret key for the Databricks service account.
##
## Parameters:
## - `gcp_region`: The region for Google Cloud resources.
## - `secret_name`: The name of the secret.
## - `secret_data`: The secret data.
##
## Providers:
## - `google.auth_session`: The Google Cloud provider.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_service_account_key_secret" {
  source      = "./modules/databricks_secret_manager"
  depends_on  = [ module.databricks_service_account ]

  gcp_region    = var.gcp_region
  secret_name   = local.client_secret_name
  secret_data   = module.databricks_service_account.gcp_databricks_service_account_key_secret

  providers = {
    google.auth_session = google.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## STAGE BUCKET MODULE
##
## This module provisions a stage bucket in Google Cloud Storage.
##
## Parameters:
## - `project_id`: The ID of the Google Cloud project.
## - `bucket_name`: The name of the stage bucket.
##
## Providers:
## - `google.auth_session`: The Google Cloud provider.
## ---------------------------------------------------------------------------------------------------------------------
module "stage_bucket" {
  source          = "github.com/rethinkr-hub/py-superhero-dataflow.git//batch/serverless_functions/gcp/modules/superhero_buckets"
  project_id      = var.gcp_project_id
  bucket_name     = "${local.prefix}-stage"

  providers = {
    google.auth_session = google.auth_session
  }
}


/* Create GCS Bucket for Output Parquet Data */
## ---------------------------------------------------------------------------------------------------------------------
## OUTPUT BUCKET MODULE
##
## This module provisions an output bucket in Google Cloud Storage.
##
## Parameters:
## - `project_id`: The ID of the Google Cloud project.
## - `bucket_name`: The name of the output bucket.
##
## Providers:
## - `google.auth_session`: The Google Cloud provider.
## ---------------------------------------------------------------------------------------------------------------------
module "output_bucket" {
  source          = "github.com/rethinkr-hub/py-superhero-dataflow.git//batch/serverless_functions/gcp/modules/superhero_buckets"
  project_id      = var.gcp_project_id
  bucket_name     = "${local.prefix}-output"

  providers = {
    google.auth_session = google.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS PROVIDER
##
## This provider configures Databricks with the necessary authentication details.
##
## Parameters:
## - `alias`: An alias for the provider.
## - `host`: The Databricks account host.
## - `google_service_account`: The service account email for Google Cloud.
## - `account_id`: The Databricks account ID.
## ---------------------------------------------------------------------------------------------------------------------
provider "databricks" {
  alias                  = "accounts"
  host                   = var.databricks_accounts_host
  google_service_account = module.service_account_auth.service_account_email
  account_id             = var.databricks_account_id
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS VPC MODULE
##
## This module configures the VPC for Databricks.
##
## Parameters:
## - `databricks_account_id`: The Databricks account ID.
## - `gcp_project_id`: The Google Cloud project ID.
## - `gcp_region`: The Google Cloud region.
##
## Providers:
## - `google.auth_session`: Authenticates with Google Cloud.
## - `databricks.accounts`: Databricks provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_vpc" {
  source                = "./modules/databricks_vpc"
  depends_on            = [ module.databricks_service_account ]

  databricks_account_id = var.databricks_account_id
  gcp_network_name      = "${local.prefix}-network"
  gcp_project_id        = var.gcp_project_id
  gcp_region            = var.gcp_region
  
  providers = {
    google.auth_session = google.auth_session
    databricks.accounts = databricks.accounts
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS MWS WORKSPACES RESOURCE
##
## This resource creates a Databricks MWS workspace.
##
## Parameters:
## - `account_id`: The Databricks account ID.
## - `workspace_name`: The name of the workspace.
## - `location`: The location of the workspace.
## - `cloud_resource_container`: Configuration for the cloud resource container.
## - `network_id`: The network ID.
## - `gke_config`: Configuration for the GKE (Google Kubernetes Engine).
##
## Dependencies:
## - `module.databricks_vpc`: Depends on the Databricks VPC module.
##
## Providers:
## - `databricks.accounts`: Databricks provider for authentication.
##
## Notes:
## - This resource requires the `databricks.accounts` provider to be configured.
## - It depends on the `module.databricks_vpc` module for network configuration.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_mws_workspaces" "this" {
  provider       = databricks.accounts
  depends_on     = [ module.databricks_vpc ]
  
  account_id     = var.databricks_account_id
  workspace_name = "${local.prefix}-workspace"
  location       = module.databricks_vpc.subnet_region
  cloud_resource_container {
    gcp {
      project_id = var.gcp_project_id
    }
  }

  network_id = module.databricks_vpc.network_id
  gke_config {
    connectivity_type = var.gcp_databricks_connectivity_type
    master_ip_range   = var.gcp_databricks_ip_range
  }

  #token {
  #  comment = "Terraform"
  #}
}
