output "databricks_host" {
  value = "https://${azurerm_databricks_workspace.this.workspace_url}/"
}

output "databricks_workspace_id" {
  description = "Databricks Workspace ID"
  value       = azurerm_databricks_workspace.this.id
}

output "databricks_workspace_number" {
  description = "Databricks Workspace ID (Number Only)"
  value       = azurerm_databricks_workspace.this.workspace_id
}

output "databricks_workspace_name" {
  description = "Databricks Workspace Name"
  value       = azurerm_databricks_workspace.this.name
}

output "azure_databricks_stage_bucket" {
  description = "Azure Stage Bucket for Databricks Stage Data"
  value       = module.stage_bucket.bucket_name
}

output "azure_databricks_output_bucket" {
  description = "Azure Output Bucket for Databricks Output Data"
  value       = module.output_bucket.bucket_name
}

output "azure_raw_bucket_dfs_host" {
  description = "Azure Raw Storage Account DFS Endpoint"
  value       = module.raw_bucket_access.storage_account_dfs_host
}

output "azure_standard_bucket_access_key" {
  description = "Azure Access Key for Standard Bucket Data"
  value       = module.standard_bucket_access.storage_account_primary_access_key
  sensitive   = true
}

output "azure_standard_bucket_dfs_host" {
  description = "Azure Standard Storage Account DFS Endpoint"
  value       = module.standard_bucket_access.storage_account_dfs_host
}

output "azure_stage_bucket_dfs_host" {
  description = "Azure Stage Storage Account DFS Endpoint"
  value       = module.stage_bucket.bucket_dfs_host
}

output "azure_output_bucket_dfs_host" {
  description = "Azure Output Storage Account DFS Endpoint"
  value       = module.output_bucket.bucket_dfs_host
}

output "azure_key_vault_name" {
  description = "Key Vault Name"
  value       = module.key_vault.key_vault_name
}

output "azure_key_vault_sa_client_id_secret_name" {
  description = "Key Vault Secret Name for Service Account Secret"
  value       = module.key_vault_client_id_secret.key_vault_secret_name
}

output "azure_key_vault_sa_client_secret_secret_name" {
  description = "Key Vault Secret Name for Service Account Secret"
  value       = module.key_vault_client_secret_secret.key_vault_secret_name
}

output "azure_resource_group_id" {
  description = "Azure Resource Group ID"
  value       = azurerm_resource_group.this.id
}

output "azure_resource_group_name" {
  description = "Azure Resource Group Name"
  value       = azurerm_resource_group.this.name
}