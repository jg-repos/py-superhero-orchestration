## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_administrator_group_id" {
  type        = string
  description = "Databricks Accounts Administrator Group ID"
}

variable "gcp_metastore_bucket_name" {
  type        = string
  description = "GCP Databricks Metastore Bucket Name"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "gcp_roles" {
  type        = string
  description = "GCP GCS Storage Roles"
  default     = "roles/storage.objectAdmin"
}

variable "gcp_service_account" {
  type        = string
  description = "GCP Databricks Metastore Data Access Service Account"
  default     = null
}