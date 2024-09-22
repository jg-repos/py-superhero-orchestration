## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_metastore_bucket_name" {
  type        = string
  description = "GCP GCS Databricks Metastore Bucket Name"
}

variable "databricks_storage_credential_name" {
  type        = string
  description = "Databricks Workspace Storage Credential Name"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------
