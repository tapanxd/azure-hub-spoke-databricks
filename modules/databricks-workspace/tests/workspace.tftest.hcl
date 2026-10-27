mock_provider "azurerm" {}

variables {
  name                              = "dbw-test"
  resource_group_name               = "rg-spoke-test"
  location                          = "eastus2"
  virtual_network_id                = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-spoke-test/providers/Microsoft.Network/virtualNetworks/vnet-spoke-test"
  public_subnet_name                = "snet-dbx-host"
  private_subnet_name               = "snet-dbx-container"
  public_subnet_id                  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-spoke-test/providers/Microsoft.Network/virtualNetworks/vnet-spoke-test/subnets/snet-dbx-host"
  private_subnet_id                 = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-spoke-test/providers/Microsoft.Network/virtualNetworks/vnet-spoke-test/subnets/snet-dbx-container"
  public_subnet_nsg_association_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-spoke-test/providers/Microsoft.Network/virtualNetworks/vnet-spoke-test/subnets/snet-dbx-host"
  private_subnet_nsg_association_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-spoke-test/providers/Microsoft.Network/virtualNetworks/vnet-spoke-test/subnets/snet-dbx-container"
  tags                              = { environment = "test" }
}

run "vnet_injection_is_wired" {
  command = plan

  assert {
    condition     = azurerm_databricks_workspace.this.custom_parameters[0].virtual_network_id == var.virtual_network_id
    error_message = "Workspace must be injected into the supplied VNet."
  }

  assert {
    condition     = azurerm_databricks_workspace.this.custom_parameters[0].public_subnet_name == "snet-dbx-host" && azurerm_databricks_workspace.this.custom_parameters[0].private_subnet_name == "snet-dbx-container"
    error_message = "Host and container subnet names must be passed through."
  }
}

run "secure_cluster_connectivity_and_nat_by_default" {
  command = plan

  assert {
    condition     = azurerm_databricks_workspace.this.custom_parameters[0].no_public_ip == true
    error_message = "no_public_ip should default to true."
  }

  assert {
    condition     = length(azurerm_nat_gateway.this) == 1 && length(azurerm_subnet_nat_gateway_association.public) == 1 && length(azurerm_subnet_nat_gateway_association.private) == 1
    error_message = "A NAT gateway should be created and attached to both subnets by default."
  }
}

run "nat_gateway_can_be_disabled" {
  command = plan

  variables {
    create_nat_gateway = false
  }

  assert {
    condition     = length(azurerm_nat_gateway.this) == 0 && length(azurerm_public_ip.nat) == 0
    error_message = "No NAT resources should be planned when create_nat_gateway = false."
  }
}

run "rejects_unknown_sku" {
  command = plan

  variables {
    sku = "enterprise"
  }

  expect_failures = [var.sku]
}
