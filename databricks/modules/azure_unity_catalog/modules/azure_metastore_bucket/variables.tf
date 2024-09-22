## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_storage_name" {
  type        = string
  description = "Databricks Workspace Storage Name"
}

variable "azure_resource_group" {
  type        = string
  description = "Azure Databricks Resource Group Name"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "azure_container_name" {
  type        = string
  description = "Azure Storage Account Container Name"
  default     = "metastore"
}

variable "tags" {
  description = "Azure Resource Tag(s)"
  default     = {}
}