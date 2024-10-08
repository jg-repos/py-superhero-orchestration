## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "gcp_region" {
  type        = string
  description = "GCP Resources & Groups Region"
}

variable "secret_name" {
  type        = string
  description = "Google Secret Manager Secret Name"
}

variable "secret_data" {
  type        = string
  description = "Google Secret Manager Secret Data"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------
