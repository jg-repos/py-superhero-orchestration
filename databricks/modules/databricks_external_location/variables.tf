## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "aws_external_bucket_name" {
  type        = string
  description = "AWS S3 External Locations Bucket for Databricks"
}

variable "databricks_storage_credential_id" {
  type        = string
  description = "Databricks Storage Credential"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_external_location_name" {
  type        = string
  description = "Databricks Workspace Unity Catalog External Location Name"
  default     = "external"
}