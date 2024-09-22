## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_workspace_id" {
  type        = number
  description = "Databricks Workspace ID"
}

variable "databricks_user" {
  type        = string
  description = "Databricks Accounts User"
}

variable "databricks_group" {
  type        = string
  description = "Databricks Accounts User Group Name"
}

variable "gcp_metastore_bucket_name" {
  type        = string
  description = "GCP Databricks Metastore Bucket Name"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "permissions" {
  type        = list(string)
  description = "Databricks Permission Rolesets"
  default     = ["USER"]
}

variable "gcp_roles" {
  type        = string
  description = "GCP GCS Storage Roles"
  default     = "roles/storage.legacyBucketReader"
}