## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_administrator_group_id" {
  type        = string
  description = "Databricks Accounts Administrator Group ID"
}

variable "databricks_administrator_service_principal_id" {
  type        = string
  description = "Databricks Accounts Service Principal Administrator ID (Same as Client ID in CLI)"
}