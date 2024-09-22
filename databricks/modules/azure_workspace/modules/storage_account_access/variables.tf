## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "bucket_name" {
  type        = string
  description = "Azure Storage Account Name"
}

variable "resource_group_name" {
  type        = string
  description = "Existing Azure Resource Group Name Owning the Azure Storage Accounts"
}

variable "security_group_id" {
  type        = string
  description = "Azure Security Group ID to Provision Storage Account Access"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------