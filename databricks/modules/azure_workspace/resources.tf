terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>3.86"
      configuration_aliases = [ azurerm.auth_session ]
    }
  }
}

resource "random_string" "this" {
  special = false
  upper   = false
  length  = 4
}

locals {
  cloud   = "azure"
  program = "spark-databricks"
  project = "datasim"
}

locals  {
  prefix                    = var.resource_prefix != null ? var.resource_prefix : "${local.program}-${local.project}-${random_string.this.id}"
  databricks_resource_group = var.databricks_resource_group != null ? var.databricks_resource_group : "${local.prefix}-resource-group"
  databricks_workspace_name = var.databricks_workspace_name != null ? var.databricks_workspace_name : "${local.prefix}-workspace"
  client_id_name            = var.azure_client_id_name != null ? var.azure_client_id_name : "${local.prefix}-sp-client-id"
  client_secret_name        = var.azure_client_secret_name != null ? var.azure_client_secret_name : "${local.prefix}-sp-client-secret"
  tags                      = merge(var.tags, {
    program = local.program
    project = local.project
    env     = "dev"
  })
}


## ---------------------------------------------------------------------------------------------------------------------
## AZURERM_RESOURCE_GROUP RESOURCE
##
## This Terraform block defines an Azure resource group using the azurerm provider with the alias 
## "auth_session". It specifies the resource group's name and location.
##
## Parameters:
## - `provider`: The alias of the Azure provider configuration to use for this resource
## - `name`: The name of the resource group
## - `location`: The location where the resource group will be created
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_resource_group" "this" {
  provider = azurerm.auth_session  # Specify the Azure provider alias for authentication
  name     = local.databricks_resource_group  # Specify the name of the resource group
  location = var.azure_region  # Specify the location where the resource group will be created
}


## ---------------------------------------------------------------------------------------------------------------------
## RAW_BUCKET_ACCESS MODULE
##
## This Terraform module configures access to a raw data storage bucket. It depends on an existing Azure resource group
## and uses a security group ID provided by the service account authentication module.
##
## Parameters:
## - `source`: The path to the module source
## - `depends_on`: A list of resources or modules that this module depends on
## - `bucket_name`: The name of the raw data storage bucket
## - `resource_group_name`: The name of the Azure resource group where the bucket resides
## - `security_group_id`: The ID of the security group used for authentication
## ---------------------------------------------------------------------------------------------------------------------
module "raw_bucket_access" {
  source              = "./modules/storage_account_access"  # Specify the path to the module source
  depends_on          = [azurerm_resource_group.this]  # Specify the dependencies of this module

  bucket_name         = var.azure_raw_bucket_name  # Specify the name of the raw data storage bucket
  resource_group_name = var.dataflow_resource_group  # Specify the name of the Azure resource group
  security_group_id   = var.azure_security_group_id  # Specify the security group ID

  providers = {
    azurerm.auth_session = azurerm.auth_session  # Specify the Azure provider alias for authentication
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## STANDARD_BUCKET_ACCESS MODULE
##
## This Terraform module configures access to a standard data storage bucket. It depends on an existing Azure resource group
## and uses a security group ID provided by the service account authentication module.
##
## Parameters:
## - `source`: The path to the module source
## - `depends_on`: A list of resources or modules that this module depends on
## - `bucket_name`: The name of the standard data storage bucket
## - `resource_group_name`: The name of the Azure resource group where the bucket resides
## - `security_group_id`: The ID of the security group used for authentication
## ---------------------------------------------------------------------------------------------------------------------
module "standard_bucket_access" {
  source              = "./modules/storage_account_access"  # Specify the path to the module source
  depends_on          = [azurerm_resource_group.this]  # Specify the dependencies of this module

  bucket_name         = var.azure_standard_bucket_name  # Specify the name of the standard data storage bucket
  resource_group_name = var.dataflow_resource_group  # Specify the name of the Azure resource group
  security_group_id   = var.azure_security_group_id  # Specify the security group ID

  providers = {
    azurerm.auth_session = azurerm.auth_session  # Specify the Azure provider alias for authentication
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## STAGE_BUCKET MODULE
##
## This Terraform module configures a stage bucket for the superhero dataflow. It depends on an existing Azure resource group
## and uses a security group ID provided by the service account authentication module.
##
## Parameters:
## - `source`: The source of the module, specifying the GitHub repository and path
## - `depends_on`: A list of resources or modules that this module depends on
## - `resource_group_name`: The name of the Azure resource group where the bucket resides
## - `resource_group_location`: The location of the Azure resource group
## - `security_group_id`: The ID of the security group used for authentication
## - `bucket_name`: The name of the stage bucket
## - `container_name`: The name of the container within the stage bucket
## ---------------------------------------------------------------------------------------------------------------------
module "stage_bucket" {
  source                  = "github.com/rethinkr-hub/py-superhero-dataflow.git//batch/serverless_functions/azure/modules/superhero_buckets"  # Specify the source of the module
  depends_on              = [azurerm_resource_group.this]  # Specify the dependencies of this module

  resource_group_name     = azurerm_resource_group.this.name  # Specify the name of the Azure resource group
  resource_group_location = var.azure_region  # Specify the location of the Azure resource group
  security_group_id       = var.azure_security_group_id  # Specify the security group ID
  bucket_name             = substr("stage${replace(local.prefix, "-", "")}", 0, 24)  # Specify the name of the stage bucket
  container_name          = "stage"  # Specify the name of the container within the stage bucket

  providers = {
    azurerm.auth_session = azurerm.auth_session  # Specify the Azure provider alias for authentication
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## OUTPUT_BUCKET MODULE
##
## This Terraform module configures an output bucket for the superhero dataflow. It depends on an existing Azure resource group
## and uses a security group ID provided by the service account authentication module.
##
## Parameters:
## - `source`: The source of the module, specifying the GitHub repository and path
## - `depends_on`: A list of resources or modules that this module depends on
## - `resource_group_name`: The name of the Azure resource group where the bucket resides
## - `resource_group_location`: The location of the Azure resource group
## - `security_group_id`: The ID of the security group used for authentication
## - `bucket_name`: The name of the output bucket
## - `container_name`: The name of the container within the output bucket
## ---------------------------------------------------------------------------------------------------------------------
module "output_bucket" {
  source                  = "github.com/rethinkr-hub/py-superhero-dataflow.git//batch/serverless_functions/azure/modules/superhero_buckets"  # Specify the source of the module
  depends_on              = [azurerm_resource_group.this]  # Specify the dependencies of this module

  resource_group_name     = azurerm_resource_group.this.name  # Specify the name of the Azure resource group
  resource_group_location = var.azure_region  # Specify the location of the Azure resource group
  security_group_id       = var.azure_security_group_id  # Specify the security group ID
  bucket_name             = substr("output${replace(local.prefix, "-", "")}", 0, 24)  # Specify the name of the output bucket
  container_name          = "output"  # Specify the name of the container within the output bucket

  providers = {
    azurerm.auth_session = azurerm.auth_session  # Specify the Azure provider alias for authentication
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## KEY_VAULT MODULE
##
## This module configures a key vault in Azure.
## 
## Parameters:
## - `source`: The path to the module.
## - `depends_on`: A list of resources or modules that this module depends on.
## - `key_vault_name`: The name of the key vault.
## - `resource_group_location`: The location of the resource group where the key vault will be created.
## - `resource_group_name`: The name of the resource group where the key vault will be created.
## - `security_group_id`: The ID of the security group associated with the key vault.
## - `providers`: A map of provider configurations for the module.
## ---------------------------------------------------------------------------------------------------------------------
module "key_vault" {
  source                  = "./modules/key_vault"
  depends_on              = [ azurerm_resource_group.this ]

  key_vault_name          = "${local.prefix}-key-vault"
  resource_group_location = azurerm_resource_group.this.location
  resource_group_name     = azurerm_resource_group.this.name
  security_group_id       = var.azure_security_group_id

  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## KEY VAULT CLIENT ID SECRET MODULE
##
## This module creates a secret in an Azure Key Vault to store the client ID.
## 
## Parameters:
## - `source`: The path to the module.
## - `depends_on`: A list of resources or modules that this module depends on.
## - `key_vault_id`: The ID of the Azure Key Vault where the secret will be stored.
## - `key_vault_secret_name`: The name of the secret to be created in the Azure Key Vault.
## - `key_vault_secret_value`: The value of the secret (in this case, the client ID).
## - `providers`: A map of provider configurations for the module.
## ---------------------------------------------------------------------------------------------------------------------
module "key_vault_client_id_secret" {
  source                  = "./modules/key_vault_secret"
  depends_on              = [ module.key_vault ]
  
  key_vault_id           = module.key_vault.key_vault_id
  key_vault_secret_name  = local.client_id_name
  key_vault_secret_value = var.azure_client_id
  
  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## KEY VAULT CLIENT SECRET MODULE
##
## This module creates a secret in an Azure Key Vault to store the client secret.
## 
## Parameters:
## - `depends_on`: A list of resources or modules that this module depends on.
## - `key_vault_id`: The ID of the Azure Key Vault where the secret will be stored.
## - `key_vault_secret_name`: The name of the secret to be created in the Azure Key Vault.
## - `key_vault_secret_value`: The value of the secret (in this case, the client secret).
## ---------------------------------------------------------------------------------------------------------------------
module "key_vault_client_secret_secret" {
  source                  = "./modules/key_vault_secret"
  depends_on              = [ module.key_vault ]
  
  key_vault_id           = module.key_vault.key_vault_id
  key_vault_secret_name  = local.client_secret_name
  key_vault_secret_value = var.azure_client_secret
  
  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## AZURERM DATABRICKS WORKSPACE RESOURCE
##
## This resource provisions an Azure Databricks workspace.
## 
## Parameters:
## - `name`: The name of the Databricks workspace.
## - `resource_group_name`: The name of the resource group where the Databricks workspace will be created.
## - `location`: The location/region where the Databricks workspace will be deployed.
## - `sku`: The SKU (stock-keeping unit) of the Databricks workspace.
## - `managed_resource_group_name`: The name of the managed resource group associated with the Databricks workspace.
## ---------------------------------------------------------------------------------------------------------------------
resource "azurerm_databricks_workspace" "this" {
  provider                    = azurerm.auth_session
  name                        = local.databricks_workspace_name
  resource_group_name         = azurerm_resource_group.this.name
  location                    = azurerm_resource_group.this.location
  sku                         = var.databricks_workspace_sku
  managed_resource_group_name = "${local.databricks_workspace_name}-resource-group"
}
