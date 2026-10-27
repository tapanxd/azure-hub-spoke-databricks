output "hub_to_spoke_id" {
  description = "Resource ID of the hub-side peering."
  value       = azurerm_virtual_network_peering.hub_to_spoke.id
}

output "spoke_to_hub_id" {
  description = "Resource ID of the spoke-side peering."
  value       = azurerm_virtual_network_peering.spoke_to_hub.id
}
