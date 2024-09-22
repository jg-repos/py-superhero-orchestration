output "databricks_metastore_bucket_arn" {
  description = "Databricks Metastore Bucket ARN"
  value       = aws_s3_bucket.this.arn
}

output "databricks_metastore_bucket_id" {
  description = "Databricks Metastore Bucket ID"
  value       = aws_s3_bucket.this.id
}