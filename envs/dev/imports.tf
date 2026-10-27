# Import blocks (Terraform >= 1.7 for for_each) adopt the click-ops network into
# the module addresses without touching Azure. `terraform plan` previews them as
# "N to import"; the first apply writes them to state.
#
# After that first apply, set import_existing = false (or delete this file).

locals {
  sub_prefix = "/subscriptions/${var.subscription_id}/resourceGroups"

  hub_rg_id        = "${local.sub_prefix}/${local.hub_rg_name}"
  spoke_rg_id      = "${local.sub_prefix}/${local.spoke_rg_name}"
  hub_vnet_id      = "${local.hub_rg_id}/providers/Microsoft.Network/virtualNetworks/${local.hub_vnet_name}"
  spoke_vnet_id    = "${local.spoke_rg_id}/providers/Microsoft.Network/virtualNetworks/${local.spoke_vnet_name}"
  hub_nsg_prefix   = "${local.hub_rg_id}/providers/Microsoft.Network/networkSecurityGroups/nsg-"
  spoke_nsg_prefix = "${local.spoke_rg_id}/providers/Microsoft.Network/networkSecurityGroups/nsg-"

  # name => name maps. Filtering with `if` (rather than `cond ? local.x : {}`)
  # avoids a type error: the spoke subnets mix delegation = null and an object,
  # so local.spoke_subnets is an object type that cannot unify with {}.
  import_hub_subnets   = { for k, s in local.hub_subnets : k => k if var.import_existing }
  import_spoke_subnets = { for k, s in local.spoke_subnets : k => k if var.import_existing }
  import_hub_nsgs      = { for k, s in local.hub_subnets : k => k if var.import_existing && s.create_nsg }
  import_spoke_nsgs    = { for k, s in local.spoke_subnets : k => k if var.import_existing && s.create_nsg }
}

# --- Resource groups ---------------------------------------------------------

import {
  for_each = var.import_existing ? { id = local.hub_rg_id } : {}
  to       = azurerm_resource_group.hub
  id       = each.value
}

import {
  for_each = var.import_existing ? { id = local.spoke_rg_id } : {}
  to       = azurerm_resource_group.spoke
  id       = each.value
}

# --- Virtual networks --------------------------------------------------------

import {
  for_each = var.import_existing ? { id = local.hub_vnet_id } : {}
  to       = module.hub.azurerm_virtual_network.this
  id       = each.value
}

import {
  for_each = var.import_existing ? { id = local.spoke_vnet_id } : {}
  to       = module.spoke_dbx.azurerm_virtual_network.this
  id       = each.value
}

# --- Subnets -----------------------------------------------------------------

import {
  for_each = local.import_hub_subnets
  to       = module.hub.azurerm_subnet.this[each.key]
  id       = "${local.hub_vnet_id}/subnets/${each.key}"
}

import {
  for_each = local.import_spoke_subnets
  to       = module.spoke_dbx.azurerm_subnet.this[each.key]
  id       = "${local.spoke_vnet_id}/subnets/${each.key}"
}

# --- NSGs and their subnet associations --------------------------------------
# The association's import ID is the ID of the subnet it is attached to.

import {
  for_each = local.import_hub_nsgs
  to       = module.hub.azurerm_network_security_group.this[each.key]
  id       = "${local.hub_nsg_prefix}${each.key}"
}

import {
  for_each = local.import_spoke_nsgs
  to       = module.spoke_dbx.azurerm_network_security_group.this[each.key]
  id       = "${local.spoke_nsg_prefix}${each.key}"
}

import {
  for_each = local.import_hub_nsgs
  to       = module.hub.azurerm_subnet_network_security_group_association.this[each.key]
  id       = "${local.hub_vnet_id}/subnets/${each.key}"
}

import {
  for_each = local.import_spoke_nsgs
  to       = module.spoke_dbx.azurerm_subnet_network_security_group_association.this[each.key]
  id       = "${local.spoke_vnet_id}/subnets/${each.key}"
}

# --- Peerings ----------------------------------------------------------------

import {
  for_each = var.import_existing ? { id = "${local.hub_vnet_id}/virtualNetworkPeerings/${local.peering_hub_to_spoke_name}" } : {}
  to       = module.peering.azurerm_virtual_network_peering.hub_to_spoke
  id       = each.value
}

import {
  for_each = var.import_existing ? { id = "${local.spoke_vnet_id}/virtualNetworkPeerings/${local.peering_spoke_to_hub_name}" } : {}
  to       = module.peering.azurerm_virtual_network_peering.spoke_to_hub
  id       = each.value
}
