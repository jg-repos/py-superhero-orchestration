## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_account_id" {
  type        = string
  description = "Databricks Account ID"
  sensitive   = true
}

variable "databricks_workspace_id" {
  type        = number
  description = "Databricks Workspace ID"
}

variable "databricks_cli_profile" {
  type        = string
  description = "Databricks CLI Configure --profile name where credentials are stored"
}

variable "databricks_administrator" {
  type        = string
  description = "Databricks Accounts Administrator"
}

variable "databricks_host" {
  type        = string
  description = "Databricks Workspace Host URL"
}

variable "databricks_token" {
  type        = string
  description = "Databrickws Workspace Service Principal Access Token"
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


## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_unity_catalog_name" {
  type        = string
  description = "Databricks Workspace Unity Catalog Name"
  default     = null
}

variable "databricks_default_catalog_name" {
  type        = string
  description = "Databricks Workspace Default Catalog Name"
  default     = "hive_metastore"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix Name to apply to Resources"
  default     = null
}
