output "databricks_host" {
  value = module.databricks_gcp_workspace.databricks_host
}

output "databricks_token" {
  value     = module.databricks_gcp_workspace.databricks_token
  sensitive = true
}

output "databricks_service_account_email"{
  value = module.databricks_gcp_workspace.databricks_service_account
}
 
output "databricks_service_account_key_name" {
  value = module.databricks_service_account_key_name_secret.databricks_secret_name
}

output "databricks_service_account_key_secret" {
  value = module.databricks_service_account_key_data_secret.databricks_secret_name
}

output "gcp_databricks_stage_bucket" {
  description = "GCS Stage Bucket for Databricks Stage Data"
  value       = module.databricks_gcp_workspace.gcp_databricks_stage_bucket
}

output "gcp_databricks_output_bucket" {
  description = "GCS Stage Bucket for Databricks Output Data"
  value       = module.databricks_gcp_workspace.gcp_databricks_output_bucket
}