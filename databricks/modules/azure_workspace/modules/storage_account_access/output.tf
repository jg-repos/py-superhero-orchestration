output "storage_account_primary_access_key" {
  sensitive = true
  value     = data.azurerm_storage_account.this.primary_access_key
}

output "storage_account_dfs_host" {
  value = data.azurerm_storage_account.this.primary_dfs_host
}