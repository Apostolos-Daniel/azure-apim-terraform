# azure-apim-terraform
An example configuration of Azure APIM using terraform

## Prereqs

- Have [`az cli` installed](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli-macos)

## Create pre-commit hooks

```
touch ./pre-commit-config.yaml
```

Copy this configuration to this new flie:

```
repos:
- repo: https://github.com/antonbabenko/pre-commit-terraform
  rev: v1.83.2
  hooks:
    - id: terraform_fmt
    - id: terraform_docs
      args:
        - --hook-config=--path-to-file=docs/README.md        # Valid UNIX path. I.e. ../TFDOC.md or docs/README.md etc.
        - --hook-config=--add-to-existing-file=true     # Boolean. true or false
        - --hook-config=--create-file-if-not-exist=true # Boolean. true or false
    - id: terraform_validate
```

## Initialise terraform for Azure resource management provider

You can find all the documentation for `azurerm` [here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/api_management).


```
touch main.tf
```

Copy this code into `main.tf`:

```
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
```

You will need to authenticate with Azure, follow [instructions here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs).

How you authenticate, depends on where you are running terraform, locally or remotely.

> We recommend using either a Service Principal or Managed Service Identity when running Terraform non-interactively (such as when running Terraform in a CI server) - and authenticating using the Azure CLI when running Terraform locally.


### Local authentication using azi cli

If you don't configure anything, the terraform provider will use the Azure CLI credentials to provision infrastructure.

If you want to find out what subscription it will providion infrastructure to, run:

```
az account show
```

To switch between azure acounts you have to log in again, run:

```
az login
```

If you want to switch between accounts, run:

```
az account set --subscription="SUBSCRIPTION_ID"
```

## Create a module for APIM

Create a module in root `main.tf`:


```
module "azure_apim" {
    source = "./modules/azure_apim"
}
```

Create a module directory and `main.tf`:

```
mkdir modules
mkdir modules/azure_apim
touch modules/azure_apim/main.tf
```

### Create a resource group

Then create a resource group within the module:

```
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
}
```

Run:

```
terraform init
```

Then run:

```
terraform plan
```

Then run:

```
terraform apply
```

To destroy the resource group, run:

```
terraform destroy
```

To verify that the resource group has been destroyed, run:

```
terraform plan
```

Or via the Azure CLI, list all resource groups by name only:

```
az group list --query '[].name' -o tsv
```

### Create an APIM instance

Create an APIM instance within the module. Note that you have to use a unique name for the APIM instance and this applies globally across Azure.

```
resource "azurerm_api_management" "example" {
  name                = "example-apim-toli-io"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  publisher_name      = "My Company"
  publisher_email     = "
}
```

Check if the apim instance exists:

```
az apim list --resource-group apim-rg --query "[].{name:name}" -o table
```

You should get something like this:

```
Name
--------------------
example-apim-toli-io
```

This creates an apim instance without any APIs. To create an API, you need to create an API product.

*Note*: this may take a few minutes to complete (it took me 28 mins).

To check if the apim instance has been created, run:

```
az apim show --name example-apim-toli-io --resource-group apim-rg --output table
```

### Add a policy to an API endpoint

Add an API endpoint to the APIM instance:

```
resource "azurerm_api_management_api" "example" {
  name                = "example-api"
  resource_group_name = azurerm_resource_group.example.name
  api_management_name = azurerm_api_management.example.name
  revision            = "1"
}
```

To view the api, run:

```
az apim api show --api-id example-api --resource-group apim-rg --service-name example-apim-toli-io --output table
```

Then add an API operation to the API:

```
resource "azurerm_api_management_api_operation" "example" {
  operation_id        = "acctest-operation"
  api_name            = azurerm_api_management_api.example.name
  api_management_name = azurerm_api_management.example.name
  resource_group_name = azurerm_resource_group.example.name
  display_name        = "DELETE Resource"
  method              = "DELETE"
  url_template        = "/resource"
}
```

To view the api operation, run:

```
az apim api operation show --api-id example-api --operation-id acctest-operation  --resource-group apim-rg --service-name example-apim-toli-io --output table
```

Finally, add a policy to the API operation:

```
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
```

You can't show this policy via the Azure CLI, but you can look it up on Azure Portal. The policy should now be updated.

## Revisions

APIM uses the concept of "revisions" to manage the lifecycle of APIs. You can create a new revision of an API and then publish it to the gateway. This allows you to make changes to the API without affecting the live version.

### Using the Azure CLI

To create a new revision of an API using az cli, run:

```
az apim api revision create --api-id example-api --resource-group apim-rg --service-name example-apim-toli-io --api-revision 2 --api-revision-description "New revision"
```

This doesn't actually make it live, this adds a revision that's not current. You can check it's not current by running:

```
az apim api revision list --api-id example-api --resource-group apim-rg --service-name example-apim-toli-io --output table
```

Not sure it's possible to make it live.


**Note**: revisions is a different concept to "versions". You can have multiple revisions of an API, but only one version. You can't have multiple versions of an API.

You may not be able to do this programmatically: https://github.com/Azure/azure-cli/issues/14695

### Using the azurerm terraform provider

You can achieve the same by using the azurerm terraform provider. 


You can check which revision is current by running:

```
az apim api revision list --api-id example-api --resource-group apim-rg --service-name example-apim-toli-io --output table
```


First, create a new revision of the API by setting the `revision` to 2 (assumming the previous version is 1):

```
resource "azurerm_api_management_api" "example" {
  name                = "example-api"
  resource_group_name = azurerm_resource_group.example.name
  api_management_name = azurerm_api_management.example.name
  revision            = "2"
  display_name        = "Example API" # <-- This attribute is required
  protocols           = ["https"]     # <-- This attribute is required

}
```

Run the same command again:

```
az apim api revision list --api-id example-api --resource-group apim-rg --service-name example-apim-toli-io --output table
```

This deletes all revisions and crates a single revision (revision 1):

```
ApiId                    ApiRevision    CreatedDateTime                   Description    IsCurrent    IsOnline    PrivateUrl    UpdatedDateTime
-----------------------  -------------  --------------------------------  -------------  -----------  ----------  ------------  --------------------------------
/apis/example-api;rev=2  2              2023-09-20T09:45:32.957000+00:00                 True         True        /             2023-09-20T09:45:32.970000+00:00
```

Not sure it's possible to simply add a new revision to existing revisions.

See [GitHub issue](https://github.com/hashicorp/terraform-provider-azurerm/issues/12720)