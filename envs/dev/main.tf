resource "azurerm_resource_group" "hub" {
  name     = local.hub_rg_name
  location = var.location
  tags     = local.tags
}

resource "azurerm_resource_group" "spoke" {
  name     = local.spoke_rg_name
  location = var.location
  tags     = local.tags
}

module "hub" {
  source = "../../modules/vnet"

  name                = local.hub_vnet_name
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  address_space       = [var.hub_address_space]
  subnets             = local.hub_subnets
  tags                = local.tags
}

module "spoke_dbx" {
  source = "../../modules/vnet"

  name                = local.spoke_vnet_name
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  address_space       = [var.spoke_address_space]
  subnets             = local.spoke_subnets
  tags                = local.tags
}

module "peering" {
  source = "../../modules/peering"

  hub = {
    name                = module.hub.name
    id                  = module.hub.id
    resource_group_name = azurerm_resource_group.hub.name
  }

  spoke = {
    name                = module.spoke_dbx.name
    id                  = module.spoke_dbx.id
    resource_group_name = azurerm_resource_group.spoke.name
  }

  hub_to_spoke_name = local.peering_hub_to_spoke_name
  spoke_to_hub_name = local.peering_spoke_to_hub_name
}

# step 2
module "databricks" {
  count  = var.enable_databricks ? 1 : 0
  source = "../../modules/databricks-workspace"

  name                = local.databricks_workspace_name
  resource_group_name = azurerm_resource_group.spoke.name
  location            = azurerm_resource_group.spoke.location
  sku                 = var.databricks_sku

  virtual_network_id  = module.spoke_dbx.id
  public_subnet_name  = module.spoke_dbx.subnet_names[local.dbx_host_subnet]
  private_subnet_name = module.spoke_dbx.subnet_names[local.dbx_container_subnet]
  public_subnet_id    = module.spoke_dbx.subnet_ids[local.dbx_host_subnet]
  private_subnet_id   = module.spoke_dbx.subnet_ids[local.dbx_container_subnet]

  public_subnet_nsg_association_id  = module.spoke_dbx.nsg_association_ids[local.dbx_host_subnet]
  private_subnet_nsg_association_id = module.spoke_dbx.nsg_association_ids[local.dbx_container_subnet]

  tags = local.tags
}
