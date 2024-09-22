## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "group_name" {
  type        = string
  description = "Databricks Group/Team Name"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "allow_cluster_create" {
  type        = bool
  description = "Allow Group to Create Clusters"
  default     = false
}

variable "allow_instance_pool_create" {
  type        = bool
  description = "Allow Group to Create Instance Pools"
  default     = false
}

variable "allow_databricks_sql_access" {
  type        = bool
  description = "Allow Group to Access Databricks SQL"
  default     = false
}