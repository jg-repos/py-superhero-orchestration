output "storage_configuration_id" {
  description = "AWS S3 Bucket Configuration ID"
  value       = databricks_mws_storage_configurations.this.storage_configuration_id
}