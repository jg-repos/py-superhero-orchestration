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

variable "aws_cli_profile" {
  type        = string
  description = "AWS CLI Configure --profile name where credentials are stored"
}

variable "aws_access_key" {
  type        = string
  description = "AWS Service Principal Access Key"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS Service Principal Secret Key"
}

variable "aws_region" {
  type        = string
  description = "AWS Cluster Region"
}

variable "aws_raw_bucket_name" {
  type        = string
  description = "AWS Existing S3 Bucket Name for Raw Data Asset Landing"
}

variable "aws_standard_bucket_name" {
  type        = string
  description = "AWS Existing S3 Bucket Name for Standardized Data Asset Landing"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "aws_access_key_name" {
  type        = string
  description = "AWS Service Principal Access Key Name"
  default     = null
}

variable "aws_secret_key_name" {
  type        = string
  description = "AWS Service Principal Secret Key Name"
  default     = null
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