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
  description = "Azure Resources & Groups Region"
}

variable "git_url" {
  type        = string
  description = "Databricks[DBX] DAB Git Repo URL"
}

variable "git_username" {
  type        = string
  description = "Git Provider User Name"
}

variable "git_pat" {
  type        = string
  description = "Git Personal Access Token"
}

variable "databricks_administrator" {
  type        = string
  description = "Databricks Workspace Administrator"
}

variable "databricks_administrator_service_principal_id" {
  type        = string
  description = "Databricks Accounts Service Principal Administrator ID (Same as Client ID in CLI)"
}

variable "databricks_cli_profile" {
  type        = string
  description = "Databricks CLI Configure --profile name where credentials are stored"
}

variable "databricks_account_id" {
  type        = string
  description = "Databricks Account ID"
  sensitive   = true
}

variable "dataflow_resource_group" {
  type        = string
  description = "Azure Dataflow Resource Group Name"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "resource_prefix" {
  type        = string
  description = "Prefix Name to apply to Resources"
  default     = null
}

variable "azure_iam_bootstrap" {
  type        = list(string)
  description = "Azure New Service Account IAM Roles to Bind"
  default     = []
}

variable "databricks_instance_pool_driver_max_capacity" {
  type        = number
  description = "Databricks Workspace Driver Instance Pool Compute Max Capacity"
  default     = 1
}

variable "databricks_instance_pool_node_max_capacity" {
  type        = number
  description = "Databricks Workspace Node Instance Pool Compute Max Capacity"
  default     = 1
}

variable "databricks_cluster_data_security_mode" {
  type        = string
  description = "Databricks Data Security Mode Attribute for Cluster Policy Running with Unity Catalog"
  default     = "USER_ISOLATION"
}

variable "databricks_secret_scope" {
  type        = string
  description = "Databricks Secret Scope Name. Referred to in CLOUD_PROVIDER ENV Variable in spark_solutions.common.service_account_credentials.py"
  default     = null
}

variable "databricks_cluster_libraries" {
  type        = list(string)
  description = "Databricks Cluster Maven Libraries to Install on Creation"
  default     = []
}

variable "tags" {
  description = "AWS Resource Tag(s)"
  default     = {}
}

variable "databricks_workspace_sku" {
  type        = string
  description = "Databricks Workspace Sku Type"
  default     = "standard"
}