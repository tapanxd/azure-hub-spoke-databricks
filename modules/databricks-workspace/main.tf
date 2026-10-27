# Explicit egress for the injected subnets. New VNets have no default outbound
# internet access (since 31 Mar 2026), and with secure cluster connectivity the
# nodes have no public IPs, so clusters cannot reach the control plane without this.

resource "azurerm_public_ip" "nat" {
  count = var.create_nat_gateway ? 1 : 0

  name                = "${var.name}-nat-pip"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_nat_gateway" "this" {
  count = var.create_nat_gateway ? 1 : 0

  name                    = "${var.name}-nat"
  resource_group_name     = var.resource_group_name
  location                = var.location
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  tags                    = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  count = var.create_nat_gateway ? 1 : 0

  nat_gateway_id       = azurerm_nat_gateway.this[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "public" {
  count = var.create_nat_gateway ? 1 : 0

  subnet_id      = var.public_subnet_id
  nat_gateway_id = azurerm_nat_gateway.this[0].id
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  count = var.create_nat_gateway ? 1 : 0

  subnet_id      = var.private_subnet_id
  nat_gateway_id = azurerm_nat_gateway.this[0].id
}

resource "azurerm_databricks_workspace" "this" {
  name                        = var.name
  resource_group_name         = var.resource_group_name
  location                    = var.location
  sku                         = var.sku
  managed_resource_group_name = var.managed_resource_group_name
  tags                        = var.tags

  custom_parameters {
    no_public_ip                                         = var.no_public_ip
    virtual_network_id                                   = var.virtual_network_id
    public_subnet_name                                   = var.public_subnet_name
    private_subnet_name                                  = var.private_subnet_name
    public_subnet_network_security_group_association_id  = var.public_subnet_nsg_association_id
    private_subnet_network_security_group_association_id = var.private_subnet_nsg_association_id
  }

  # Attach egress before the workspace takes ownership of the subnets.
  depends_on = [
    azurerm_nat_gateway_public_ip_association.this,
    azurerm_subnet_nat_gateway_association.public,
    azurerm_subnet_nat_gateway_association.private,
  ]
}
