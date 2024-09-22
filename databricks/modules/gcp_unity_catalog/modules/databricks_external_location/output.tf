output "databricks_storage_credential_id" {
    description = "Databrick Workspace Storage Credential External ID"
    value       = databricks_storage_credential.this.id
}

output "databricks_external_location_url" {
    description = "Databricks External Location GCS URL"
    value       = "gcs://${var.databricks_metastore_bucket_name}/metastore"
}