output "databricks_administrator_group" {
    description = "Databricks Administrator Unity Catalog Group Name"
    value       = module.databricks_admin_group.databricks_group_name
}

output "databricks_user_group" {
    description = "Databricks User Unity Catalog Group Name"
    value       = module.databricks_user_group.databricks_group_name
}