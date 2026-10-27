output "id" {
  description = "Resource ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "Name of the virtual network."
  value       = azurerm_virtual_network.this.name
}

output "subnet_ids" {
  description = "Map of subnet name => subnet resource ID."
  value       = { for k, s in azurerm_subnet.this : k => s.id }
}

output "subnet_names" {
  description = "Map of subnet name => subnet name (handy for for_each over module outputs)."
  value       = { for k, s in azurerm_subnet.this : k => s.name }
}

output "nsg_ids" {
  description = "Map of subnet name => NSG resource ID, for subnets that have an NSG."
  value       = { for k, n in azurerm_network_security_group.this : k => n.id }
}

output "nsg_association_ids" {
  description = "Map of subnet name => subnet/NSG association ID. Databricks VNet injection needs these."
  value       = { for k, a in azurerm_subnet_network_security_group_association.this : k => a.id }
}
