output "unity_catalog_iam_arn" {
    description = "Databrick Workspace Storage Credential IAM ARN"
    value       = databricks_storage_credential.this.aws_iam_role[0].unity_catalog_iam_arn
}

output "databricks_storage_credential_iam_external_id" {
    description = "Databrick Workspace Storage Credential External ID"
    value       = databricks_storage_credential.this.aws_iam_role[0].external_id
}

output "databricks_storage_credential_id" {
    description = "Databrick Workspace Storage Credential External ID"
    value       = databricks_storage_credential.this.id
}

output "databricks_external_location_url" {
    description = "Databricks External Location S3 URL"
    value       = "s3://${var.databricks_metastore_bucket_id}/metastore"
}