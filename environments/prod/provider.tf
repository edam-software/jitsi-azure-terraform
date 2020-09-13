terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.41.0"
    }
  }
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}