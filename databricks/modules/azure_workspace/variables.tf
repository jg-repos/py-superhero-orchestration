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

variable "azure_client_id" {
    type         = string
    description  = "Azure Service Account Client ID"
}

variable "azure_client_secret" {
    type         = string
    description  = "Azure Service Account Client Secret"
}

variable "azure_security_group_id" {
  type        = string
  description = "Azure Security Group ID with Access to Storage Account Buckets"
}

variable "azure_raw_bucket_name" {
  type        = string
  description = "Existing Azure Storage Account Name for Raw Data Landing"
}

variable "azure_standard_bucket_name" {
  type        = string
  description = "Existing Azure Storage Account Name for Standard Data Landing"
}

variable "azure_region" {
  type        = string
  description = "Azure Resources & Group Region"
}

variable "dataflow_resource_group" {
  type        = string
  description = "Azure Dataflow Resource Group Name"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "azure_client_id_name" {
    type         = string
    description  = "Azure Service Account Client ID Name"
    default      = null
}

variable "azure_client_secret_name" {
    type         = string
    description  = "Azure Service Account Client Secret Name"
    default      = null
}

variable "databricks_workspace_sku" {
  type        = string
  description = "Databricks Workspace Sku Type"
  default     = "standard"
}

variable "databricks_resource_group" {
  type        = string
  description = "Azure Databricks Resource Group Name"
  default     = null
}

variable "databricks_workspace_name" {
  type        = string
  description = "Databricks Workspace Name"
  default     = null
}

variable "resource_prefix" {
  type        = string
  description = "Prefix Name to apply to Resources"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Azure Resource Tag(s)"
  default     = {}
}