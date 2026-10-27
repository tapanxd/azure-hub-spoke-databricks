terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Local state. See backend.tf.example before sharing this with anyone.
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}
