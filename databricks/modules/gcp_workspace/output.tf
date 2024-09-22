output "databricks_host" {
  value = databricks_mws_workspaces.this.workspace_url
}

output "databricks_token" {
  value     = databricks_mws_workspaces.this.token[0].token_value
  sensitive = true
}

output "databricks_service_account" {
  description = "GCP Impersonatable Databricks Service Account"
  value       = module.service_account_auth.service_account_email
}

output "gcp_databricks_service_account_key_name" {
  description = "GCP Service Account Key Name for Use Within Databricks"
  value       = module.databricks_service_account.gcp_databricks_service_account_key_name
  sensitive   = true
}

output "gcp_databricks_service_account_key_secret" {
  description = "GCP Service Account Key Secret for Use Within Databricks"
  value       = module.databricks_service_account.gcp_databricks_service_account_key_secret
  sensitive   = true
}

output "gcp_databricks_stage_bucket" {
  description = "GCS Stage Bucket for Databricks Stage Data"
  value       = module.standard_bucket.bucket_name
}

output "gcp_databricks_output_bucket" {
  description = "GCS Stage Bucket for Databricks Output Data"
  value       = module.output_bucket.bucket_name
}