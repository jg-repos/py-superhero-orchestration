## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_metastore_bucket_arn" {
    type        = string
    description = "Databricks Unity Catalog Metastore S3 Bucket ARN"
}

variable "databricks_unity_catalog_role_name" {
  type        = string
  description = "Databricks Workspace Unity Catalog Role Name"
}

variable "unity_catalog_iam_arn" {
    type        = string
    description = "Databrick Workspace Storage Credential IAM ARN"
}

variable "databricks_storage_credential_iam_external_id" {
    type        = string
    description = "Databrick Workspace Storage Credential External ID"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "tags" {
  description = "AWS Resource Tag(s)"
  default     = {}
}