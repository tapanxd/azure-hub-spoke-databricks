locals {
  env  = var.environment
  tags = merge({ environment = local.env }, var.extra_tags)

  # must match legacy/bootstrap.sh
  hub_rg_name     = "rg-hub-${local.env}"
  spoke_rg_name   = "rg-spoke-dbx-${local.env}"
  hub_vnet_name   = "vnet-hub-${local.env}"
  spoke_vnet_name = "vnet-spoke-dbx-${local.env}"

  peering_hub_to_spoke_name = "peer-hub-to-spoke-dbx"
  peering_spoke_to_hub_name = "peer-spoke-dbx-to-hub"

  databricks_workspace_name = "dbw-${local.env}"

  hub_shared_subnet     = "snet-shared"
  dbx_host_subnet       = "snet-dbx-host"
  dbx_container_subnet  = "snet-dbx-container"
  spoke_workload_subnet = "snet-workload"

  # "0" because az names delegations by index. Anything else is drift on import.
  databricks_delegation = {
    name         = "0"
    service_name = "Microsoft.Databricks/workspaces"
    actions = [
      "Microsoft.Network/virtualNetworks/subnets/join/action",
      "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
      "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
    ]
  }

  # bootstrap.sh hardcodes the results of these
  hub_subnets = {
    (local.hub_shared_subnet) = {
      address_prefixes                = [cidrsubnet(var.hub_address_space, 2, 0)]
      create_nsg                      = true
      default_outbound_access_enabled = false
      delegation                      = null
    }
  }

  spoke_subnets = {
    (local.dbx_host_subnet) = {
      address_prefixes                = [cidrsubnet(var.spoke_address_space, 3, 0)]
      create_nsg                      = true
      default_outbound_access_enabled = false
      delegation                      = local.databricks_delegation
    }
    (local.dbx_container_subnet) = {
      address_prefixes                = [cidrsubnet(var.spoke_address_space, 3, 1)]
      create_nsg                      = true
      default_outbound_access_enabled = false
      delegation                      = local.databricks_delegation
    }
    (local.spoke_workload_subnet) = {
      address_prefixes                = [cidrsubnet(var.spoke_address_space, 2, 1)]
      create_nsg                      = true
      default_outbound_access_enabled = false
      delegation                      = null
    }
  }
}
