terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.73.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {}
}

module "azure_apim" {
    source = "./modules/azure_apim"
}