mock_provider "azurerm" {}

variables {
  name                = "vnet-test"
  resource_group_name = "rg-test"
  location            = "eastus2"
  address_space       = ["10.9.0.0/22"]
  tags                = { environment = "test" }

  subnets = {
    "snet-app" = {
      address_prefixes = ["10.9.0.0/24"]
    }
    "GatewaySubnet" = {
      address_prefixes = ["10.9.1.0/27"]
      create_nsg       = false
    }
    "snet-dbx-host" = {
      address_prefixes = ["10.9.2.0/25"]
      delegation = {
        name         = "databricks"
        service_name = "Microsoft.Databricks/workspaces"
        actions = [
          "Microsoft.Network/virtualNetworks/subnets/join/action",
          "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
          "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
        ]
      }
    }
  }
}

run "one_subnet_per_map_entry" {
  command = plan

  assert {
    condition     = length(azurerm_subnet.this) == 3
    error_message = "Expected one azurerm_subnet per entry in var.subnets."
  }
}

run "nsg_only_where_requested" {
  command = plan

  assert {
    condition     = length(azurerm_network_security_group.this) == 2
    error_message = "Expected NSGs for snet-app and snet-dbx-host only."
  }

  assert {
    condition     = !contains(keys(azurerm_network_security_group.this), "GatewaySubnet")
    error_message = "GatewaySubnet must not get an NSG."
  }

  assert {
    condition     = azurerm_network_security_group.this["snet-app"].name == "nsg-snet-app"
    error_message = "NSG names should be <prefix>-<subnet name>."
  }
}

run "subnets_are_private_by_default" {
  command = plan

  assert {
    condition     = alltrue([for s in azurerm_subnet.this : s.default_outbound_access_enabled == false])
    error_message = "Subnets should default to default_outbound_access_enabled = false."
  }
}

run "delegation_is_applied_only_where_set" {
  command = plan

  assert {
    condition     = azurerm_subnet.this["snet-dbx-host"].delegation[0].service_delegation[0].name == "Microsoft.Databricks/workspaces"
    error_message = "snet-dbx-host should be delegated to Microsoft.Databricks/workspaces."
  }

  assert {
    condition     = length(azurerm_subnet.this["snet-app"].delegation) == 0
    error_message = "snet-app should have no delegation."
  }
}

run "rejects_invalid_address_space" {
  command = plan

  variables {
    address_space = ["not-a-cidr"]
  }

  expect_failures = [var.address_space]
}

run "rejects_invalid_subnet_cidr" {
  command = plan

  variables {
    subnets = {
      "snet-bad" = { address_prefixes = ["10.9.0.0/99"] }
    }
  }

  expect_failures = [var.subnets]
}
