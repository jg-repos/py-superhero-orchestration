## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_account_id" {
  type        = string
  description = "Databricks Account ID"
  sensitive   = true
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "aws_bucket_name" {
  type        = string
  description = "AWS Bucket Name for Databricks Accounts"
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "AWS Resource Tag(s)"
  default     = {}
}