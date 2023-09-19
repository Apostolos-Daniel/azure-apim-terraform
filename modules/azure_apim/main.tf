resource "azurerm_resource_group" "example" {
  name     = "apim-rg"
  location = "West Europe"
}

resource "azurerm_api_management" "example" {
  name                = "example-apim-toli-io"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  publisher_name      = "toli.io"
  publisher_email     = "dev@toli.io"

  sku_name = "Developer_1"
}
