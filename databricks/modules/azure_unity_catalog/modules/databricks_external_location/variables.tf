## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_access_connector_id" {
  type        = string
  description = "Azure Databricks Access Connector ID"
}

variable "databricks_external_location_url" {
  type        = string
  description = "Azure Metastore Bucket abfss URL"
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