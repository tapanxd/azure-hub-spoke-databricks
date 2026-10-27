variable "name" {
  description = "Name of the Databricks workspace. Also used as the base name for the NAT gateway and its public IP."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for the workspace (normally the spoke's resource group)."
  type        = string
}

variable "location" {
  description = "Azure region. Must match the region of the injected VNet."
  type        = string
}

variable "sku" {
  description = "Workspace SKU."
  type        = string
  default     = "premium"

  validation {
    condition     = contains(["standard", "premium", "trial"], var.sku)
    error_message = "sku must be one of: standard, premium, trial."
  }
}

variable "managed_resource_group_name" {
  description = "Name for the Databricks-managed resource group. Null lets Azure generate one. Changing it forces a new workspace."
  type        = string
  default     = null
}

variable "virtual_network_id" {
  description = "Resource ID of the VNet the workspace is injected into."
  type        = string
}

variable "public_subnet_name" {
  description = "Name of the host (\"public\") subnet. Must be delegated to Microsoft.Databricks/workspaces."
  type        = string
}

variable "private_subnet_name" {
  description = "Name of the container (\"private\") subnet. Must be delegated to Microsoft.Databricks/workspaces."
  type        = string
}

variable "public_subnet_id" {
  description = "Resource ID of the host subnet. Used to attach the NAT gateway."
  type        = string
}

variable "private_subnet_id" {
  description = "Resource ID of the container subnet. Used to attach the NAT gateway."
  type        = string
}

variable "public_subnet_nsg_association_id" {
  description = "ID of the NSG association on the host subnet."
  type        = string
}

variable "private_subnet_nsg_association_id" {
  description = "ID of the NSG association on the container subnet."
  type        = string
}

variable "no_public_ip" {
  description = "Secure cluster connectivity: cluster nodes get no public IPs. Requires explicit egress (see create_nat_gateway)."
  type        = bool
  default     = true
}

variable "create_nat_gateway" {
  description = "Create a NAT gateway with a static public IP and attach it to both subnets. Set false if egress is provided another way (e.g. a hub firewall with UDRs)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags applied to the workspace, NAT gateway and public IP."
  type        = map(string)
  default     = {}
}
