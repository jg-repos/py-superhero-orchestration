variable "databricks_account_id" {
  type        = string
  description = "Databricks Account ID"
  sensitive   = true
}

variable "databricks_cli_profile" {
  type        = string
  description = "Databricks CLI Configure --profile name where credentials are stored"
}

variable "gcp_project_id" {
  type        = string
  description = "GCP Project ID"
}

variable "gcp_region" {
  type        = string
  description = "GCP Resources & Groups Region"
}

variable "impersonate_service_account_email" {
  type        = string
  description = "GCP Service Account Email equiped with sufficient Project IAM roles to create new Service Accounts"
}

variable "impersonate_user_email" {
  type        = string
  description = "GCP Impersonation User with Service Account IAM bindings for Access Token Generation"
}

variable "git_url" {
  type        = string
  description = "Databricks[DBX] Notebook/Task Git Repo URL"
}

variable "git_username" {
  type        = string
  description = "Git Provider User Name"
}

variable "git_pat" {
  type        = string
  description = "Git Personal Access Token"
}

variable "notification_recipients" {
  type        = list(string)
  description = "Email Recipient List to Receive Notifications"
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

variable "gcp_iam_bootstrap" {
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
  description = "GCP Resource Tag(s)"
  default     = {}
}