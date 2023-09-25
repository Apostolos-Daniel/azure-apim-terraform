resource "azurerm_resource_group" "example_resource_group" {
  name     = "apim-example-rg"
  location = "West Europe"
}

resource "azurerm_api_management" "example_apim" {
  name                = "example-apim-toli-io"
  location            = azurerm_resource_group.example_resource_group.location
  resource_group_name = azurerm_resource_group.example_resource_group.name
  publisher_name      = "toli.io"
  publisher_email     = "dev@toli.io"

  sku_name = "Developer_1"
}

resource "azurerm_api_management_api" "example_api" {
  name                = "example-api"
  resource_group_name = azurerm_resource_group.example_resource_group.name
  api_management_name = azurerm_api_management.example_apim.name
  revision            = "6"
  display_name        = "Example API" # <-- This attribute is required
  protocols           = ["https"]     # <-- This attribute is required

}

resource "azurerm_api_management_api_operation" "example_api_operation" {
  operation_id        = "acctest-operation"
  api_name            = azurerm_api_management_api.example_api.name
  api_management_name = azurerm_api_management.example_apim.name
  resource_group_name = azurerm_resource_group.example_resource_group.name
  display_name        = "DELETE Resource"
  method              = "DELETE"
  url_template        = "/resource"
}