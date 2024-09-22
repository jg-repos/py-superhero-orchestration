output "databricks_metastore_bucket_name" {
  description = "Databricks Metastore Bucket Name"
  value       = google_storage_bucket.this.name
}