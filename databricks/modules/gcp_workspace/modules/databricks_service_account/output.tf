output "gcp_databricks_service_account_key_name" {
  description = "GCP Service Account Key Name for Use Within Databricks"
  value       = google_service_account_key.this.name
  sensitive   = true
}

output "gcp_databricks_service_account_key_secret" {
  description = "GCP Service Account Key Secret for Use Within Databricks"
  value       = base64decode(google_service_account_key.this.private_key)
  sensitive   = true
}