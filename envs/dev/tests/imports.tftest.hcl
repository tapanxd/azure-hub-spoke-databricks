# Offline check of the two migration steps. Mock providers cannot import, so
# every imported resource gets an override_resource; the overridden IDs only
# need to be well formed enough for azurerm's ID parsers.

mock_provider "azurerm" {}

override_resource {
  target = azurerm_resource_group.hub
}

override_resource {
  target = azurerm_resource_group.spoke
}

override_resource {
  target = module.hub.azurerm_virtual_network.this
  values = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet" }
}

override_resource {
  target = module.spoke_dbx.azurerm_virtual_network.this
  values = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet" }
}

override_resource {
  target = module.hub.azurerm_subnet.this
  values = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
}

override_resource {
  target = module.spoke_dbx.azurerm_subnet.this
  values = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/virtualNetworks/vnet/subnets/snet" }
}

override_resource {
  target = module.hub.azurerm_network_security_group.this
  values = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/networkSecurityGroups/nsg" }
}

override_resource {
  target = module.spoke_dbx.azurerm_network_security_group.this
  values = { id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg/providers/Microsoft.Network/networkSecurityGroups/nsg" }
}

override_resource {
  target = module.hub.azurerm_subnet_network_security_group_association.this
}

override_resource {
  target = module.spoke_dbx.azurerm_subnet_network_security_group_association.this
}

override_resource {
  target = module.peering.azurerm_virtual_network_peering.hub_to_spoke
}

override_resource {
  target = module.peering.azurerm_virtual_network_peering.spoke_to_hub
}

variables {
  subscription_id = "00000000-0000-0000-0000-000000000000"
}

run "step1_import_only_plans" {
  command = plan

  variables {
    import_existing   = true
    enable_databricks = false
  }

  assert {
    condition     = length(module.databricks) == 0
    error_message = "The import step must not create the Databricks workspace."
  }

  assert {
    condition     = length(local.import_spoke_subnets) == 3 && length(local.import_spoke_nsgs) == 3 && length(local.import_hub_nsgs) == 1
    error_message = "Expected import blocks for 1 hub and 3 spoke subnets/NSGs."
  }
}

run "step2_databricks_without_imports" {
  command = plan

  variables {
    import_existing   = false
    enable_databricks = true
  }

  assert {
    condition     = length(local.import_hub_subnets) == 0 && length(local.import_spoke_subnets) == 0
    error_message = "import_existing = false must produce no import blocks."
  }

  assert {
    condition     = length(module.databricks) == 1
    error_message = "enable_databricks = true must add the Databricks module."
  }
}
