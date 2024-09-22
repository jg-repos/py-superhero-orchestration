## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_unity_admin_group" {
  type        = string
  description = "Databricks Accounts Admin Group Name"
}

variable "databricks_workspace_ids" {
  type        = list(string)
  description = <<EOT
  List of Databricks workspace IDs to be enabled with Unity Catalog.
  Enter with square brackets and double quotes
  e.g. ["111111111", "222222222"]
  EOT
}

variable "databricks_storage_root" {
  type        = string
  description = "Databricks Accounts Storage Root ID"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_metastore_name" {
  type        = string
  description = "Display Name for Databricks Accounts Metastore"
  default     = "Primary"
}

variable "databricks_catalog_name" {
  type        = string
  description = "Display Name for Databricks Accounts Metastore Catalog"
  default     = "hive_metastore"
}

variable "aws_region" {
  type        = string
  description = "AWS Provider Region"
  default     = "us-east-1"
}