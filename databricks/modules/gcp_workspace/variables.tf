## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_account_id" {
  type        = string
  description = "Databricks Account ID"
  sensitive   = true
}

variable "gcp_project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "gcp_region" {
  type        = string
  description = "GCP Resources & Groups Region"
}

variable "gcp_access_token" {
  type        = string
  description = "GCP Service Account Access Token"
}

variable "gcp_impersonate_user_email" {
  type        = string
  description = "GCP Impersonation User with Service Account IAM bindings for Access Token Generation"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_accounts_host" {
  type        = string
  description = "Databricks Account Default Host URL"
  default     = "https://accounts.gcp.databricks.com"
}

variable "gcp_access_token_name" {
  type        = string
  description = "GCP Service Account Access Token Name"
  default     = null
}

variable "gcp_databricks_ip_range" {
  type        = string
  description = "GCP GKE Workspace Node IP Range for Databricks"
  default     = "10.3.0.0/28"
}

variable "gcp_databricks_connectivity_type" {
  type        = string
  description = "GCP GKE Workspace Node Connectivity Type for Databricks"
  default     = "PRIVATE_NODE_PUBLIC_MASTER"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix Name to apply to Resources"
  default     = null
}