## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "gcp_project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "gcp_impersonate_user_email" {
  type        = string
  description = "GCP Impersonation User with Service Account IAM bindings for Access Token Generation"
}

variable "service_account_email" {
  type        = string
  description = "GCP Service Account Email equiped with sufficient Project IAM roles to deploy new Databricks Workspaces"
}

variable "service_account_name" {
  type        = string
  description = "GCP Service Account Name for IAM Policy"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "gcp_iam_permissions" {
  type        = list(string)
  description = "GCP IAM Permissions to authorize Service Account to Resources"
  default     = []
}