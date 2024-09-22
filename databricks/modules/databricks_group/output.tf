output "databricks_group_name" {
  description = "Databricks Group/Team Name"
  value       = databricks_group.this.display_name
}