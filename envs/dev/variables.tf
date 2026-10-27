variable "subscription_id" {
  description = "Azure subscription ID that holds the existing hub-spoke network."
  type        = string

  validation {
    condition     = can(regex("^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$", var.subscription_id))
    error_message = "subscription_id must be a GUID."
  }
}

variable "location" {
  description = "Azure region of the existing network (and of the new Databricks workspace)."
  type        = string
  default     = "eastus2"
}

variable "environment" {
  description = "Environment suffix used in resource names and the environment tag. Must match what legacy/bootstrap.sh created (ENV)."
  type        = string
  default     = "dev"
}

variable "hub_address_space" {
  description = "Address space of the hub VNet. Must match the existing VNet."
  type        = string
  default     = "10.0.0.0/22"
}

variable "spoke_address_space" {
  description = "Address space of the Databricks spoke VNet. Must match the existing VNet. Databricks requires a prefix between /16 and /24."
  type        = string
  default     = "10.1.0.0/22"

  validation {
    condition     = tonumber(split("/", var.spoke_address_space)[1]) >= 16 && tonumber(split("/", var.spoke_address_space)[1]) <= 24
    error_message = "Databricks VNet injection requires the VNet prefix to be between /16 and /24."
  }
}

variable "import_existing" {
  description = "Emit import blocks for the existing resources. Set to false (or delete imports.tf) once the first apply has put them in state."
  type        = bool
  default     = true
}

variable "enable_databricks" {
  description = "Create the NAT gateway and the VNet-injected Databricks workspace. Leave false for the import-only step so the plan can be asserted to be a no-op."
  type        = bool
  default     = false
}

variable "databricks_sku" {
  description = "Databricks workspace SKU."
  type        = string
  default     = "premium"
}

variable "extra_tags" {
  description = "Additional tags. Keep empty for the import step: any tag not already on the Azure resources shows up as an in-place update."
  type        = map(string)
  default     = {}
}
