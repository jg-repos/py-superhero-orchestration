## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_account_id" {
  type        = string
  description = "Databricks Account ID"
  sensitive   = true
}

variable "gcp_project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "gcp_region" {
  type        = string
  description = "GCP Resources & Groups Region"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "gcp_network_name" {
  type        = string
  description = "GCP VPC Network Name for Databricks Workspace"
  default     = null
}

variable "cidr_block" {
  type        = string
  description = "Virtual Internal IP Address Block Range"
  default     = "10.4.0.0/16"
}

variable "cidr_block_secondary" {
  type        = string
  description = "Virtual Internal IP Secondary Address Block Range"
  default     = "10.2.0.0/20"
}