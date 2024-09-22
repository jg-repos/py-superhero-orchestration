## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_account_id" {
  type        = string
  description = "Databricks Account ID"
  sensitive   = true
}

variable "databricks_cli_profile" {
  type        = string
  description = "Databricks CLI Configure --profile name where credentials are stored"
}

variable "databricks_administrator" {
  type        = string
  description = "Databricks Workspace Administrator"
}

variable "aws_cli_profile" {
  type        = string
  description = "AWS CLI Configure --profile name where credentials are stored"
}

variable "aws_raw_bucket" {
  type        = string
  description = "AWS Existing S3 Bucket Name for Raw Data Asset Landing"
}

variable "aws_standard_bucket" {
  type        = string
  description = "AWS Existing S3 Bucket Name for Standardized Data Asset Landing"
}

variable "aws_region" {
  type        = string
  description = "AWS Provider Region"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

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

variable "aws_iam_bootstrap" {
  type        = list(string)
  description = "AWS New Service Account IAM Roles to Bind"
  default     = []
}

variable "databricks_cluster_libraries" {
  type        = list(string)
  description = "Databricks Cluster Maven Libraries to Install on Creation"
  default     = []
}

variable "resource_prefix" {
  type        = string
  description = "Prefix Name to apply to Resources"
  default     = null
}

variable "tags" {
  description = "AWS Resource Tag(s)"
  default     = {}
}