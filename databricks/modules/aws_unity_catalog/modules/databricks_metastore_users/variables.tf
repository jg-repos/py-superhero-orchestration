## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_account_id" {
  type        = string
  description = "Databricks Account ID"
  sensitive   = true
}

variable "databricks_workspace_id" {
  type        = number
  description = "Databricks Workspace ID"
}

variable "databricks_administrator" {
  type        = string
  description = "Databricks Accounts Administrator"
}

variable "databricks_administrator_group" {
    type        = string
    description = "Databricks Unity Catalog Administrator Group"
}

variable "databricks_user_group" {
    type        = string
    description = "Databricks Unity Catalog User Group"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------