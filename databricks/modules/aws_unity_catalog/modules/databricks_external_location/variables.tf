## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_metastore_bucket_id" {
  type        = string
  description = "Databricks Metastore Bucket ID"
}

variable "databricks_metastore_cross_account_policy_arn" {
    type        = string
    description = "Databricks Meta Store Cross Account Policy ARN (Statically Types)"
}

variable "databricks_storage_credential_name" {
  type        = string
  description = "Databricks Workspace Storage Credential Name"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "tags" {
  description = "AWS Resource Tag(s)"
  default     = {}
}