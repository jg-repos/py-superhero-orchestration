output "databricks_host" {
  description = "Databricks Workspace Host URL"
  value       = module.databricks_azure_workspace.databricks_host
}

output "databricks_token" {
  description = "Databricks Workspace Personal Access Token (PAT)"
  value       = module.databricks_token.databricks_token
  sensitive   = true
}

output "databricks_cluster_id" {
  description = "Databricks All-Purpose Compute Cluster ID"
  value       = module.databricks_cluster.databricks_cluster_id
}

output "azure_databricks_raw_bucket" {
  description = "Azure Raw Bucket DFS Endpoint"
  value       = module.databricks_azure_workspace.azure_raw_bucket_dfs_host
}

output "azure_databricks_standard_bucket" {
  description = "Azure Standard Bucket DFS Endpoint"
  value       = module.databricks_azure_workspace.azure_standard_bucket_dfs_host
}

output "azure_databricks_stage_bucket" {
  description = "Azure Stage Bucket for Databricks Stage Data"
  value       = module.databricks_azure_workspace.azure_stage_bucket_dfs_host
}

output "azure_databricks_output_bucket" {
  description = "Azure Stage Bucket for Databricks Output Data"
  value       = module.databricks_azure_workspace.azure_output_bucket_dfs_host
}

output "databricks_repo_path" {
  description = "Databricks Repo Artifact Path"
  value       = module.databricks_repo.repo_path
}

output "azure_key_vault_name" {
  description = "Key Vault Name"
  value       = module.databricks_azure_workspace.azure_key_vault_name
}

output "azure_key_vault_client_id_secret_name" {
  description = "Key Vault Secret Name for Service Account Secret"
  value       = module.databricks_azure_workspace.azure_key_vault_sa_client_id_secret_name
}

output "azure_key_vault_client_secret_secret_name" {
  description = "Key Vault Secret Name for Service Account Secret"
  value       = module.databricks_azure_workspace.azure_key_vault_sa_client_secret_secret_name
}