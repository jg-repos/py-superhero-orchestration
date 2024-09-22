output "databricks_host" {
  value = databricks_mws_workspaces.this.workspace_url
}

output "databricks_token" {
  value     = databricks_mws_workspaces.this.token[0].token_value
  sensitive = true
}

output "databricks_workspace_id" {
  description = "Databricks Workspace ID (Number Only)"
  value       = databricks_mws_workspaces.this.workspace_id
}

output "aws_client_id_secret_name" {
  description = "AWS Service Principal Client ID"
  value       = module.aws_secret_client_id.secret_name
}

output "aws_client_secret_secret_name" {
  description = "AWS Service Principal Client ID"
  value       = module.aws_secret_client_secret.secret_name
}

output "aws_raw_bucket_name" {
  description = "AWS S3 Bucket for Raw Data Asset Landing"
  value       = data.aws_s3_bucket.raw.bucket
}

output "aws_standard_bucket_name" {
  description = "AWS S3 Bucket for Standardized Data Asset Landing"
  value       = data.aws_s3_bucket.standard.bucket
}

output "aws_stage_bucket_name" {
  description = "AWS S3 Bucket for Staged Data Asset Landing"
  value       = module.aws_stage_bucket.bucket_id
}

output "aws_output_bucket_name" {
  description = "AWS S3 Bucket for Output Data Asset Landing"
  value       = module.aws_output_bucket.bucket_id
}