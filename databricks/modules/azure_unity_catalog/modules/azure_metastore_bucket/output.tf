output "access_connector_id" {
  description = "Azure Databricks Access Connector ID"
  value       = azurerm_databricks_access_connector.this.id
}

output "databricks_external_location_url" {
  description = "Azure Metastore Bucket abfss URL"
  value       = "abfss://metastore@${azurerm_storage_account.this.name}.dfs.core.windows.net"
}