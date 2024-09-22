## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_storage_credential_name" {
  type        = string
  description = "Databricks Workspace Storage Credential Name"
}

variable "gcp_region" {
  type        = string
  description = "GCP Resources & Groups Region"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------