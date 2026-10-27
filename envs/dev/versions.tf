terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Local state is fine for a first import dry run. For anything shared, copy
  # backend.tf.example to backend.tf (azurerm backend) and re-run `terraform init`.
}

provider "azurerm" {
  features {}

  subscription_id = var.subscription_id
}
