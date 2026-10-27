variable "hub" {
  description = "The hub virtual network: name, resource ID and resource group."
  type = object({
    name                = string
    id                  = string
    resource_group_name = string
  })
}

variable "spoke" {
  description = "The spoke virtual network: name, resource ID and resource group."
  type = object({
    name                = string
    id                  = string
    resource_group_name = string
  })
}

variable "hub_to_spoke_name" {
  description = "Name of the peering created on the hub side."
  type        = string
}

variable "spoke_to_hub_name" {
  description = "Name of the peering created on the spoke side."
  type        = string
}

variable "allow_forwarded_traffic" {
  description = "Allow traffic forwarded from outside the peered VNet (needed when a hub firewall/NVA routes spoke traffic). Applied to both directions."
  type        = bool
  default     = false
}

variable "hub_allow_gateway_transit" {
  description = "Let the spoke use the hub's VPN/ExpressRoute gateway."
  type        = bool
  default     = false
}

variable "spoke_use_remote_gateways" {
  description = "Make the spoke use the hub's gateway. Requires hub_allow_gateway_transit."
  type        = bool
  default     = false

  validation {
    condition     = !var.spoke_use_remote_gateways || var.hub_allow_gateway_transit
    error_message = "spoke_use_remote_gateways requires hub_allow_gateway_transit = true."
  }
}
