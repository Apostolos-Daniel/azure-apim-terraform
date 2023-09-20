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

resource "azurerm_api_management_api" "example" {
  name                = "example-api"
  resource_group_name = azurerm_resource_group.example.name
  api_management_name = azurerm_api_management.example.name
  revision            = "1"
  display_name        = "Example API" # <-- This attribute is required
  protocols           = ["https"]     # <-- This attribute is required

}

resource "azurerm_api_management_api_operation" "example" {
  operation_id        = "acctest-operation"
  api_name            = azurerm_api_management_api.example.name
  api_management_name = azurerm_api_management.example.name
  resource_group_name = azurerm_resource_group.example.name
  display_name        = "DELETE Resource"
  method              = "DELETE"
  url_template        = "/resource"
}

resource "azurerm_api_management_api_operation_policy" "example" {
  api_name            = azurerm_api_management_api_operation.example.api_name
  api_management_name = azurerm_api_management_api_operation.example.api_management_name
  resource_group_name = azurerm_api_management_api_operation.example.resource_group_name
  operation_id        = azurerm_api_management_api_operation.example.operation_id

  xml_content = <<XML
<policies>
  <inbound>
    <find-and-replace from="xyz" to="abc" />
  </inbound>
</policies>
XML

}