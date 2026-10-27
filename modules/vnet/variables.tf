variable "name" {
  description = "Name of the virtual network."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that holds the virtual network, its subnets and NSGs. The group itself is managed by the caller."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "address_space" {
  description = "CIDR blocks for the virtual network."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0 && alltrue([for c in var.address_space : can(cidrhost(c, 0))])
    error_message = "address_space must contain at least one valid CIDR block."
  }
}

variable "subnets" {
  description = <<-EOT
    Map of subnet name => settings. The map key is the subnet name.
      - address_prefixes: CIDR blocks for the subnet.
      - create_nsg: create and associate an NSG named "<nsg_name_prefix>-<subnet name>". Set false for reserved subnets such as GatewaySubnet.
      - default_outbound_access_enabled: false = "private subnet" (Azure's default for new VNets since 31 Mar 2026). Egress must then be explicit (NAT gateway, firewall).
      - delegation: optional service delegation, e.g. Microsoft.Databricks/workspaces.
  EOT
  type = map(object({
    address_prefixes                = list(string)
    create_nsg                      = optional(bool, true)
    default_outbound_access_enabled = optional(bool, false)
    delegation = optional(object({
      name         = string
      service_name = string
      actions      = optional(list(string), [])
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for s in values(var.subnets) : length(s.address_prefixes) > 0 && alltrue([for c in s.address_prefixes : can(cidrhost(c, 0))])
    ])
    error_message = "Every subnet needs at least one address prefix, and each must be a valid CIDR block."
  }
}

variable "nsg_name_prefix" {
  description = "Prefix for NSG names; the subnet name is appended."
  type        = string
  default     = "nsg"
}

variable "tags" {
  description = "Tags applied to the virtual network and NSGs."
  type        = map(string)
  default     = {}
}
