## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "azure_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "azure_tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "azure_region" {
  type        = string
  description = "Azure Resources & Group Region"
}

variable "azure_client_id" {
    type         = string
    description  = "Azure Service Account Client ID"
}

variable "azure_client_secret" {
    type         = string
    description  = "Azure Service Account Client Secret"
}

variable "azure_resource_group_name" {
  type        = string
  description = "Azure Databricks Resource Group Name"
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks Account ID"
  sensitive   = true
}

variable "databricks_administrator" {
  type        = string
  description = "Databricks Accounts Administrator"
}

variable "databricks_administrator_service_principal_id" {
  type        = string
  description = "Databricks Accounts Service Principal Administrator ID (Same as Client ID in CLI)"
}

variable "databricks_workspace_name" {
  type        = string
  description = "Databricks Workspace Name"
}

variable "databricks_workspace_id" {
  type        = string
  description = "Databricks Workspace ID"
}

variable "databricks_workspace_number" {
  type        = number
  description = "Databricks Workspace ID (Number Only)"
}

variable "databricks_workspace_host" {
  type        = string
  description = "Databricks Workspace Host URL"
}

variable "databricks_cli_profile" {
  type        = string
  description = "Databricks CLI Configure --profile name where credentials are stored"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_unity_catalog_name" {
  type        = string
  description = "Databricks Workspace Unity Catalog Name"
  default     = null
}

variable "databricks_default_catalog_name" {
  type        = string
  description = "Databricks Workspace Default Catalog Name"
  default     = "hive_metastore"
}

variable "resource_prefix" {
  type        = string
  description = "Prefix Name to apply to Resources"
  default     = null
}

variable "tags" {
  description = "Azure Resource Tag(s)"
  default     = {}
}