terraform{
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.47.0"
      configuration_aliases = [ google.auth_session ]
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
  prefix  = "${local.program}-${local.project}-${random_string.this.id}"
  iam_permissions = distinct(concat(var.gcp_iam_permissions,
  [
    "iam.serviceAccounts.getIamPolicy",
    "iam.serviceAccounts.setIamPolicy",
    "iam.roles.create",
    "iam.roles.delete",
    "iam.roles.get",
    "iam.roles.update",
    "resourcemanager.projects.get",
    "resourcemanager.projects.getIamPolicy",
    "resourcemanager.projects.setIamPolicy",
    "serviceusage.services.get",
    "serviceusage.services.list",
    "serviceusage.services.enable",
    "compute.networks.get",
    "compute.projects.get",
    "compute.subnetworks.get",
  ]))
}

## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE IAM POLICY DATA SOURCE
##
## This data source retrieves the IAM policy for a Google Cloud resource.
##
## Providers:
## - `google.auth_session`: Google provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
data "google_iam_policy" "this" {
  provider = google.auth_session

  binding {
    role    = "roles/iam.serviceAccountTokenCreator"
    members = [ "user:${var.gcp_impersonate_user_email}" ]
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE SERVICE ACCOUNT IAM POLICY RESOURCE
##
## This resource manages the IAM policy for a Google Cloud service account.
##
## Parameters:
## - `service_account_id`: The ID of the Google Cloud service account.
## - `policy_data`: The IAM policy data retrieved using the `google_iam_policy` data source.
##
## Providers:
## - `google.auth_session`: Google provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_service_account_iam_policy" "this" {
  provider           = google.auth_session
  service_account_id = var.service_account_name
  policy_data        = data.google_iam_policy.this.policy_data
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE PROJECT IAM CUSTOM ROLE RESOURCE
##
## This resource defines a custom IAM role for a Google Cloud project.
##
## Parameters:
## - `project`: The ID of the Google Cloud project.
## - `role_id`: The ID of the custom IAM role.
## - `title`: The title of the custom IAM role.
## - `permissions`: The list of permissions granted to the custom IAM role.
##
## Providers:
## - `google.auth_session`: Google provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_project_iam_custom_role" "this" {
  provider    = google.auth_session
  project     = var.gcp_project_id
  role_id     = "${local.prefix}-workspace-creator"
  title       = "${local.prefix} Workspace Creator"
  permissions = var.gcp_iam_permissions
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE CLIENT CONFIG DATA SOURCE
##
## This data source retrieves the current Google Cloud client configuration.
##
## Providers:
## - `google.auth_session`: Google provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
data "google_client_config" "current" {
  provider = google.auth_session
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE PROJECT IAM MEMBER RESOURCE
##
## This resource grants a custom IAM role to a service account in a Google Cloud project.
##
## Parameters:
## - `project`: The ID of the Google Cloud project.
## - `role`: The ID of the custom IAM role to grant.
## - `member`: The email address of the service account to grant the role to.
##
## Providers:
## - `google.auth_session`: Google provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_project_iam_member" "this" {
  provider = google.auth_session
  project  = var.gcp_project_id
  role     = google_project_iam_custom_role.this.id
  member   = "serviceAccount:${var.service_account_email}"
}


## ---------------------------------------------------------------------------------------------------------------------
## GOOGLE SERVICE ACCOUNT KEY RESOURCE
##
## This resource generates a new key for a Google service account.
##
## Parameters:
## - `service_account_id`: The ID of the service account for which to create the key.
##
## Providers:
## - `google.auth_session`: Google provider for authentication.
## ---------------------------------------------------------------------------------------------------------------------
resource "google_service_account_key" "this" {
  provider           = google.auth_session
  service_account_id = var.service_account_name
}
