output "group_ip" {
    description = "Databricks Account Group ID"
    value       = data.databricks_group.this.id
}
