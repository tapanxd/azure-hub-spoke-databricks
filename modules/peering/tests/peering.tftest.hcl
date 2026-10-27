mock_provider "azurerm" {}

variables {
  hub = {
    name                = "vnet-hub"
    id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-hub/providers/Microsoft.Network/virtualNetworks/vnet-hub"
    resource_group_name = "rg-hub"
  }
  spoke = {
    name                = "vnet-spoke"
    id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-spoke/providers/Microsoft.Network/virtualNetworks/vnet-spoke"
    resource_group_name = "rg-spoke"
  }
  hub_to_spoke_name = "peer-hub-to-spoke"
  spoke_to_hub_name = "peer-spoke-to-hub"
}

run "creates_both_directions" {
  command = plan

  assert {
    condition     = azurerm_virtual_network_peering.hub_to_spoke.virtual_network_name == "vnet-hub" && azurerm_virtual_network_peering.hub_to_spoke.resource_group_name == "rg-hub"
    error_message = "hub_to_spoke must live on the hub VNet and resource group."
  }

  assert {
    condition     = azurerm_virtual_network_peering.spoke_to_hub.virtual_network_name == "vnet-spoke" && azurerm_virtual_network_peering.spoke_to_hub.resource_group_name == "rg-spoke"
    error_message = "spoke_to_hub must live on the spoke VNet and resource group."
  }

  assert {
    condition     = azurerm_virtual_network_peering.hub_to_spoke.remote_virtual_network_id == var.spoke.id && azurerm_virtual_network_peering.spoke_to_hub.remote_virtual_network_id == var.hub.id
    error_message = "Each peering must point at the opposite VNet."
  }
}

run "gateway_flags_default_off" {
  command = plan

  assert {
    condition     = !azurerm_virtual_network_peering.hub_to_spoke.allow_gateway_transit && !azurerm_virtual_network_peering.spoke_to_hub.use_remote_gateways
    error_message = "Gateway transit / remote gateways should default to false."
  }
}

run "gateway_transit_pair_is_accepted" {
  command = plan

  variables {
    hub_allow_gateway_transit = true
    spoke_use_remote_gateways = true
  }

  assert {
    condition     = azurerm_virtual_network_peering.hub_to_spoke.allow_gateway_transit && azurerm_virtual_network_peering.spoke_to_hub.use_remote_gateways
    error_message = "Gateway transit flags should be passed through."
  }
}

run "remote_gateways_without_transit_is_rejected" {
  command = plan

  variables {
    spoke_use_remote_gateways = true
  }

  expect_failures = [var.spoke_use_remote_gateways]
}
