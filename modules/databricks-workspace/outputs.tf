output "id" {
  description = "Azure resource ID of the workspace."
  value       = azurerm_databricks_workspace.this.id
}

output "workspace_id" {
  description = "Numeric Databricks workspace ID."
  value       = azurerm_databricks_workspace.this.workspace_id
}

output "workspace_url" {
  description = "Workspace URL (without scheme)."
  value       = azurerm_databricks_workspace.this.workspace_url
}

output "managed_resource_group_id" {
  description = "Resource ID of the Databricks-managed resource group."
  value       = azurerm_databricks_workspace.this.managed_resource_group_id
}

output "nat_gateway_id" {
  description = "Resource ID of the NAT gateway, or null if create_nat_gateway is false."
  value       = one(azurerm_nat_gateway.this[*].id)
}

output "nat_public_ip_address" {
  description = "Static egress IP of the NAT gateway (useful for allow-listing), or null if no NAT gateway."
  value       = one(azurerm_public_ip.nat[*].ip_address)
}
