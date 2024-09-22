output "databricks_host" {
  value = module.databricks_aws_workspace.databricks_host
}

output "databricks_token" {
  value     = module.databricks_aws_workspace.databricks_token
  sensitive = true
}

output "aws_raw_bucket_name" {
  value     = module.databricks_aws_workspace.aws_raw_bucket_name
}

output "aws_standard_bucket_name" {
  value     = module.databricks_aws_workspace.aws_standard_bucket_name
}

output "aws_stage_bucket_name" {
  value     = module.databricks_aws_workspace.aws_stage_bucket_name
}

output "aws_output_bucket_name" {
  value     = module.databricks_aws_workspace.aws_output_bucket_name
}

output "aws_client_id_secret_name" {
  description = "AWS Service Principal Client ID Name"
  value       = module.databricks_aws_workspace.aws_client_id_secret_name
}

output "aws_client_secret_secret_name" {
  description = "AWS Service Principal Client Secret Name"
  value       = module.databricks_aws_workspace.aws_client_secret_secret_name
}