output "databricks_storage_credential_id" {
    description = "Databrick Workspace Storage Credential External ID"
    value       = databricks_storage_credential.this.id
}