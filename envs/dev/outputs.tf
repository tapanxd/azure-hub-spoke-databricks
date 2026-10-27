output "hub_vnet_id" {
  description = "Resource ID of the hub VNet."
  value       = module.hub.id
}

output "spoke_vnet_id" {
  description = "Resource ID of the Databricks spoke VNet."
  value       = module.spoke_dbx.id
}

output "databricks_workspace_url" {
  description = "Databricks workspace URL, or null while enable_databricks = false."
  value       = one(module.databricks[*].workspace_url)
}

output "databricks_nat_public_ip" {
  description = "Static egress IP used by Databricks clusters, or null while enable_databricks = false."
  value       = one(module.databricks[*].nat_public_ip_address)
}
