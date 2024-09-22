terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
      version = "~> 2.47"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~> 3.86"
    }
    databricks = {
      source = "databricks/databricks"
      version = "~> 1.39.0"
    }
  }
}

terraform {
  backend "azurerm" {}
}

provider "azuread" {
  alias = "tokengen"
}

provider "azurerm" {
  alias = "tokengen"
  features {}
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS Accounts PROVIDER
##
## This section defines the Databricks Accounts Provider with an alias for managing accounts.
##
## Parameters:
## - `alias`: Alias for the provider.
## - `profile`: The CLI profile for Databricks.
## ---------------------------------------------------------------------------------------------------------------------
provider "databricks" {
  alias      = "accounts"
  profile    = var.databricks_cli_profile
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
  secret_scope        = var.databricks_secret_scope != null ? var.databricks_secret_scope : "${upper(local.cloud)}"
  prefix              = var.resource_prefix != null ? var.resource_prefix : "${local.program}-${local.project}-${random_string.this.id}"
  iam_roles = distinct(concat(var.azure_iam_bootstrap, [
    "Microsoft.Resources/subscriptions/providers/read",
    "Microsoft.Resources/subscriptions/resourceGroups/*",
    "Microsoft.Authorization/roleAssignments/*",
    "Microsoft.Databricks/*",
    "Microsoft.Storage/storageAccounts/*",
    "Microsoft.KeyVault/vaults/*",
    "Microsoft.KeyVault/locations/deletedVaults/*",
    "Microsoft.KeyVault/locations/operationResults/*"
  ]))

  maven_libraries = distinct(concat(var.databricks_cluster_libraries, [
    "org.apache.hadoop:hadoop-azure-datalake:3.3.3",
    "org.apache.hadoop:hadoop-common:3.3.3",
    "org.apache.hadoop:hadoop-azure:3.3.3"
  ]))

  tags    = merge(var.tags, {
    program = local.program
    project = local.project
    env     = "dev"
  })
}

## ---------------------------------------------------------------------------------------------------------------------
## AZURE SERVICE ACCOUNT AUTHENTICATION MODULE
## 
## This module sets up authentication for the service account used in the orchestration of superhero datasim.
## 
## Parameters:
## - `role_name`: Specify the name of the Custom IAM Role
## - `secruity_group_name`: Specify the name of the security group
## - `application_display_name`:Specify the display name of the Azure Client application
## - `client_secret_expiration`: Specify in Hours the expiration duration for the client secret
## - `roles_list`: Specify the list of Azure IAM roles to bind to Application
## ---------------------------------------------------------------------------------------------------------------------
module "service_account_auth" {
  source                   = "github.com/rethinkr-hub/py-superhero-dataflow.git//batch/serverless_functions/azure/modules/service_account_auth"
  role_name                = "${local.prefix}-service-account-role"
  security_group_name      = "${local.prefix}-security-group"
  application_display_name = "${local.prefix}-service-account"
  client_secret_expiration = "180h"
  roles_list               = local.iam_roles

  providers = {
    azuread.tokengen = azuread.tokengen
    azurerm.tokengen = azurerm.tokengen
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## TIME_SLEEP RESOURCE
##
## This resource adds a delay to wait for the Service Account Credentials to Propogate.
##
## Parameters:
## - `create_duration`: The duration to wait before completing module databricks_azure_workspace.
##
## Dependencies:
## - `module.service_account_auth`: The Service Account Creation module.
## ---------------------------------------------------------------------------------------------------------------------
resource "time_sleep" "wait_for_credentials" {
  depends_on       = [
    module.service_account_auth
  ]
  create_duration  = "120s"  # Adjust the duration as needed
}

## ---------------------------------------------------------------------------------------------------------------------
## PROVIDER "AZURERM"
##
## This Terraform block configures the Azure provider with an alias "auth_session" for authenticating using the service 
## account credentials obtained from the `service_account_auth` module.  
##
## Parameters:
## - `alias`: Alias used to reference this provider configuration in other parts of the Terraform configuration
## - `client_id`: The client ID used for authentication
## - `client_secret`: The client secret used for authentication
## - `subscription_id`: The ID of the Azure subscription
## - `tenant_id`: The ID of the Azure Active Directory tenant
## ---------------------------------------------------------------------------------------------------------------------
provider "azurerm" {
  alias = "auth_session"

  # Specify the client ID for authentication
  client_id       = module.service_account_auth.client_id

  # Specify the client secret for authentication
  client_secret   = module.service_account_auth.client_secret

  # Specify the subscription ID
  subscription_id = var.azure_subscription_id

  # Specify the tenant ID
  tenant_id       = var.azure_tenant_id
  
  # Configure features for key vault
  features {
    key_vault {
      # Enable purging soft deleted secrets on destroy
      purge_soft_deleted_secrets_on_destroy = true
      
      # Enable recovering soft deleted secrets
      recover_soft_deleted_secrets          = true
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## CREATE AZURE DATABRICKS WORKSPACE MODULE
## 
## The provided Terraform module definition is for creating an Azure Databricks workspace. 
## 
## Parameters:
## - `source`: Specifies the path to the module source code. In this case, it's expected to be in the 
##             "../modules/azure_workspace" directory.
## - `azure_region`: Specifies the Azure region where the Databricks workspace will be created.
## - `azure_subscription_id`: Specifies the ID of the Azure subscription.
## - `azure_tenant_id`: Specifies the ID of the Azure Active Directory tenant.
## - `databricks_workspace_sku`: Specifies the SKU (stock-keeping unit) for the Databricks workspace. In this case, 
##                               it's set to "premium".
## - `dataflow_resource_group`: Specifies the resource group where Dataflow resources are located.
## - `providers`: Specifies the providers used for authentication. In this case, it includes providers for 
##                Azure Active Directory (azuread.tokengen) and Azure Resource Manager (azurerm.tokengen).
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_azure_workspace" {
  source                     = "../modules/azure_workspace"
  depends_on                 = [ time_sleep.wait_for_credentials ]

  azure_region               = var.azure_region
  azure_subscription_id      = var.azure_subscription_id
  azure_tenant_id            = var.azure_tenant_id
  azure_raw_bucket_name      = var.azure_raw_bucket_name
  azure_standard_bucket_name = var.azure_standard_bucket_name
  azure_client_id            = module.service_account_auth.client_id
  azure_client_secret        = module.service_account_auth.client_secret
  azure_security_group_id    = module.service_account_auth.security_group_id
  databricks_workspace_sku   = var.databricks_workspace_sku
  dataflow_resource_group    = var.dataflow_resource_group

  providers = {
    azurerm.auth_session = azurerm.auth_session
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS WORKSPACE PROVIDER
##
## This Terraform configuration defines a Databricks provider block, which establishes a connection to an 
## Azure Databricks workspace. Here's a breakdown of the configuration:
## 
## Parameters:
## - alias: Specifies an alias for the Databricks provider. This allows you to have multiple Databricks 
##          provider configurations with different settings.
## - host: Specifies the hostname of the Databricks workspace. It is obtained from the module.databricks_
##         azure_workspace.databricks_host output of the databricks_azure_workspace module.
## - azure_workspace_resource_id: Specifies the resource ID of the Databricks workspace. It is obtained 
##                                from the module.databricks_azure_workspace.databricks_resource_id 
##                                output of the databricks_azure_workspace module.
## - azure_client_id: Specifies the client ID used for Azure authentication. It is obtained from the 
##                    module.databricks_azure_workspace.client_id output of the databricks_azure_workspace module.
## - azure_client_secret: Specifies the client secret used for Azure authentication. It is obtained 
##                        from the module.databricks_azure_workspace.client_secret output of the 
##                        databricks_azure_workspace module.
## - azure_tenant_id: Specifies the Azure tenant ID. It is provided as a variable var.azure_tenant_id.
## ---------------------------------------------------------------------------------------------------------------------
provider "databricks" {
  alias                       = "workspace"  # Alias for the Databricks provider
  host                        = module.databricks_azure_workspace.databricks_host  # Hostname of the Databricks workspace
  azure_workspace_resource_id = module.databricks_azure_workspace.databricks_workspace_id  # Resource ID of the Databricks workspace
  azure_client_id             = module.service_account_auth.client_id  # Client ID for Azure authentication
  azure_client_secret         = module.service_account_auth.client_secret  # Client secret for Azure authentication
  azure_tenant_id             = var.azure_tenant_id  # Azure tenant ID
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS UNITY CATALOG MODULE
##
## This module sets up the Databricks Unity Catalog on Azure.
##
## Parameters:
## - `azure_subscription_id`: The ID of the Azure subscription.
## - `azure_tenant_id`: The ID of the Azure tenant.
## - `azure_resource_group_name`: The name of the Azure resource group.
## - `azure_client_id`: The client ID for Azure authentication.
## - `azure_client_secret`: The client secret for Azure authentication.
## - `azure_region`: The Azure region.
## - `databricks_account_id`: The ID of the Databricks account.
## - `databricks_administrator`: The administrator for the Databricks account.
## - `databricks_cli_profile`: The CLI profile for Databricks.
## - `databricks_workspace_name`: The name of the Databricks workspace.
## - `databricks_workspace_id`: The ID of the Databricks workspace.
## - `databricks_workspace_host`: The host of the Databricks workspace.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_unity_catalog" {
  source                                        = "../modules/azure_unity_catalog"
  depends_on                                    = [ module.databricks_azure_workspace ]
  azure_subscription_id                         = var.azure_subscription_id
  azure_tenant_id                               = var.azure_tenant_id
  azure_resource_group_name                     = module.databricks_azure_workspace.azure_resource_group_name
  azure_client_id                               = module.service_account_auth.client_id
  azure_client_secret                           = module.service_account_auth.client_secret
  azure_region                                  = var.azure_region
  databricks_account_id                         = var.databricks_account_id
  databricks_administrator                      = var.databricks_administrator
  databricks_administrator_service_principal_id = var.databricks_administrator_service_principal_id
  databricks_cli_profile                        = var.databricks_cli_profile
  databricks_workspace_name                     = module.databricks_azure_workspace.databricks_workspace_name
  databricks_workspace_id                       = module.databricks_azure_workspace.databricks_workspace_id
  databricks_workspace_number                   = module.databricks_azure_workspace.databricks_workspace_number
  databricks_workspace_host                     = module.databricks_azure_workspace.databricks_host

  providers = {
    azurerm.auth_session = azurerm.auth_session
    databricks.accounts  = databricks.accounts
    databricks.workspace = databricks.workspace
  }
}



## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS ADMIN USER MODULE
##
## This module creates an administrator user in Databricks.
## 
## Parameters:
## - `user_name`: Specifies the name of the administrator user
## ---------------------------------------------------------------------------------------------------------------------
/*
module "databricks_admin_user" {
  source     = "../modules/databricks_user"
  depends_on = [ module.databricks_azure_workspace ]
  user_name = var.databricks_administrator

  providers = {
    databricks.workspace = databricks.workspace
  }
}
*/

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SECRET SCOPE MODULE
## 
## This module creates a Databricks secret scope in an Azure Databricks workspace.
## 
## Parameters:
## - `secret_scope`: Specifies the name of Databricks Secret Scope. This value will refer back to the
##                   CLOUD_PROVIDER Env Variable in spark_solutions.common.service_account_credentials.py
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_secret_scope" {
  source       = "../modules/databricks_secret_scope"
  depends_on   = [ module.databricks_unity_catalog ]

  secret_scope = local.secret_scope

  providers = {
    databricks.workspace = databricks.workspace
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SERVICE ACCOUNT KEY NAME SECRET MODULE
## 
## This module creates a secret named "databricks-sa-key-name" in a Databricks secret scope.
## The secret stores the client ID of an Azure service principal
## 
## Parameters:
## - `secret_scope_id`: Specifies the secret scope ID where the secret will be stored
## - `secret_name`: Specifies the name of the secret
## - `secret_data`: Specifies the data of the secret (client ID of the Azure service principal)
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_service_account_key_name_secret" {
  source          = "../modules/databricks_secret"
  depends_on   = [ module.databricks_unity_catalog ]
  secret_scope_id = module.databricks_secret_scope.databricks_secret_scope_id
  secret_name     = module.databricks_azure_workspace.azure_key_vault_sa_client_id_secret_name
  secret_data     = module.service_account_auth.client_id
  
  providers = {
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SERVICE ACCOUNT KEY SECRET MODULE
## 
## This module creates a secret named "databricks-sa-key-secret" in a Databricks secret scope.
## The secret stores the client Secret of an Azure service principal
## 
## Parameters:
## - `secret_scope_id`: Specifies the secret scope ID where the secret will be stored
## - `secret_name`: Specifies the name of the secret
## - `secret_data`: Specifies the data of the secret (client Secret of the Azure service principal)
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_service_account_key_data_secret" {
  source          = "../modules/databricks_secret"
  depends_on   = [ module.databricks_unity_catalog ]
  secret_scope_id = module.databricks_secret_scope.databricks_secret_scope_id
  secret_name     = module.databricks_azure_workspace.azure_key_vault_sa_client_secret_secret_name
  secret_data     = module.service_account_auth.client_secret

  providers = {
    databricks.workspace = databricks.workspace
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS DATAFLOW ACCESS KEY SECRET MODULE
## 
## This module creates a secret in a Databricks secret scope to store the access key
## for an Azure Storage Blob container.
## 
## Parameters:
## - `secret_scope_id`: Specifies the secret scope ID where the secret will be stored
## - `secret_name`: Specifies the name of the secret
## - `secret_data`: Specifies the data of the secret (access key for the Azure Storage Blob container)
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_dataflow_access_key_secret" {
  source          = "../modules/databricks_secret"
  depends_on   = [ module.databricks_unity_catalog ]
  secret_scope_id = module.databricks_secret_scope.databricks_secret_scope_id
  secret_name     = "${local.prefix}-access-key-secret"
  secret_data     = module.databricks_azure_workspace.azure_standard_bucket_access_key
  
  providers = {
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS PERSONAL ACCESS TOKEN MODULE
## 
## This module creates a personal access token (PAT) in a Databricks workspace.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_token" {
  source = "../modules/databricks_pat_token"

  providers = {
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS DRIVER NODE INSTANCE POOL MODULE
## 
## This module creates an instance pool in a Databricks workspace specifically for driver nodes.
## 
## Parameters:
## - `instance_pool_name`: Specifies the name of the instance pool
## - `instance_pool_max_capacity`: Specifies the maximum capacity of the instance pool
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_instance_pool_driver" {
  source                     = "../modules/databricks_instace_pool"
  depends_on   = [ module.databricks_unity_catalog ]
  instance_pool_name         = "${local.prefix}-driver-instance-pool"
  instance_pool_max_capacity = var.databricks_instance_pool_driver_max_capacity

  providers = {
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS WORKER NODE INSTANCE POOL MODULE
## 
## This module creates an instance pool in a Databricks workspace specifically for worker nodes.
## 
## Parameters:
## - `instance_pool_name`: Specifies the name of the instance pool
## - `instance_pool_max_capacity`: Specifies the maximum capacity of the instance pool
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_instance_pool_node" {
  source                     = "../modules/databricks_instace_pool"
  depends_on   = [ module.databricks_unity_catalog ]
  instance_pool_name         = "${local.prefix}-node-instance-pool"
  instance_pool_max_capacity = var.databricks_instance_pool_node_max_capacity

  providers = {
    databricks.workspace = databricks.workspace
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS REPOSITORY MOODULE
## 
## This module connects a Git repository to the Databricks workspace.
## 
## Parameters:
## - `git_url`: Specifies the Git Repository URL
## - `git_username`: Specifies the Git Username to access the repository
## - `git_pat`: Specifies the Personal Access Token (PAT) to authenticate with the repository
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_repo" {
  source       = "../modules/databricks_repo"
  depends_on   = [ module.databricks_unity_catalog ]
  git_url      = var.git_url
  git_username = var.git_username
  git_pat      = var.git_pat

  providers = {
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS ENGINEER GROUP MODULE
## 
## This module sets up an engineer group in a Databricks workspace.
## 
## Parameters:
## - `group_name`: Specifies the name of the engineer group.
## - `allow_cluster_create`: Specify whether to allow the group to create clusters.
## - `allow_databricks_sql_access`: Specify whether to allow SQL access to Databricks.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_engineer_group" {
  source                      = "../modules/databricks_group"
  depends_on   = [ module.databricks_unity_catalog ]
  group_name                  = "${local.prefix}-engineer-group"
  allow_cluster_create        = true
  allow_databricks_sql_access = true

  providers = {
    databricks.workspace = databricks.workspace
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS CLUSTER POLICY MODULE
## 
## This module sets up a cluster policy in a Databricks workspace.
## 
## Parameters:
## - `cluster_policy_name`: Specifies the name of the cluster policy.
## - `group_name`: Specify the name of the engineer group to associate the policy with.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_cluster_policy" {
  source              = "../modules/databricks_cluster_policy"
  depends_on          = [module.databricks_engineer_group]
  cluster_policy_name = "${local.prefix}-cluster-policy"
  group_name          = module.databricks_engineer_group.databricks_group_name
  data_security_mode  = var.databricks_cluster_data_security_mode

  providers = {
    databricks.workspace = databricks.workspace
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS CLUSTER MODULE
## 
## This module sets up a Databricks cluster with the specified configurations.
## 
## Parameters:
## - `cluster_name`: Specify the name of the Databricks cluster.
## - `node_instance_pool_id`: Specify the instance pool IDs for worker nodes.
## - `driver_instance_pool_id`: Specify the instance pool IDs for driver nodes.
## - `cluster_policy_name`: Specify the name of the cluster policy.
## - `cluster_policy_id`: Specify the ID of the cluster policy.
## - `spark_env_variable`: Define Spark environment variables.
## - `spark_conf_variable`: Define Spark configuration variables.
## - `maven_libraries`: Define Maven libraries for the cluster.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_cluster" {
  source                  = "../modules/databricks_cluster"
  depends_on              = [module.databricks_cluster_policy]
  cluster_name            = "${local.prefix}-cluster"
  node_instance_pool_id   = module.databricks_instance_pool_node.instance_pool_id
  driver_instance_pool_id = module.databricks_instance_pool_driver.instance_pool_id
  cluster_policy_name     = module.databricks_cluster_policy.cluster_policy_name
  cluster_policy_id       = module.databricks_cluster_policy.cluster_policy_id
  maven_libraries         = local.maven_libraries

  # Define Spark environment variables
  spark_env_variable      = {
    "CLOUD_PROVIDER": upper(local.cloud),
    "RAW_DIR": "abfss://raw@${module.databricks_azure_workspace.azure_raw_bucket_dfs_host}",
    "STANDARD_DIR": "abfss://standard@${module.databricks_azure_workspace.azure_standard_bucket_dfs_host}",
    "STAGE_DIR": "abfss://stage@${module.databricks_azure_workspace.azure_stage_bucket_dfs_host}",
    "OUTPUT_DIR": "abfss://output@${module.databricks_azure_workspace.azure_output_bucket_dfs_host}",
    "SERVICE_ACCOUNT_KEY_NAME": module.databricks_azure_workspace.azure_key_vault_sa_client_id_secret_name,
    "SERVICE_ACCOUNT_KEY_SECRET": module.databricks_azure_workspace.azure_key_vault_sa_client_secret_secret_name,
    "AZURE_TENANT_ID": var.azure_tenant_id
  }

  # Define Spark configuration variables
  spark_conf_variable     = {
    "fs.azure.account.auth.type": "OAuth",
    "fs.azure.account.oauth.provider.type": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
    "fs.azure.account.oauth2.client.id": "{{secrets/${module.databricks_secret_scope.databricks_secret_scope_id}/${module.databricks_service_account_key_name_secret.databricks_secret_name}}}",
    "fs.azure.account.oauth2.client.secret": "{{secrets/${module.databricks_secret_scope.databricks_secret_scope_id}/${module.databricks_service_account_key_data_secret.databricks_secret_name}}}",
    "fs.azure.account.oauth2.client.endpoint": "https://login.microsoftonline.com/${var.azure_tenant_id}/oauth2/token",
    "spark.databricks.driver.strace.enabled": "true"
  }

  providers = {
    databricks.workspace = databricks.workspace
  }
}