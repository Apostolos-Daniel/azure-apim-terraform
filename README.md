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

This creates an apim instance with a single API. To list the APIs, run:

```
az apim api list --resource-group apim-rg --service-name example-apim-toli-io --query "[].{name:name}" -o table
```

*Note*: this may take a few minutes to complete (it took me 28 mins).

To check if the apim instance has been created, run:

```bash
az apim show --name example-apim-toli-io --resource-group apim-rg --output table
```

### Add an API endpoint

Add an API endpoint to the APIM instance:

```t
resource "azurerm_api_management_api" "example" {
  name                = "example-api"
  resource_group_name = azurerm_resource_group.example.name
  api_management_name = azurerm_api_management.example.name
  revision            = "1"
}
```

To view the api, run:

```bash
az apim api show --api-id example-api --resource-group apim-rg --service-name example-apim-toli-io --output table
```

This will return something along the lines of:


ApiRevision  |  ApiRevisionDescription  |  ApiVersion    ApiVersionDescription  |  Description |   DisplayName   | IsCurrent    Name      |   Path  |  ResourceGroup  |  ServiceUrl   | SubscriptionRequired
------------- |  ------------------------ | ------------  ----------------------- | ------------- | ------------- | -----------  |----------- | ------ | --------------- | ------------  |----------------------
5        |                                                                           |           Example API   | True       |  example-api    |      apim-rg          |              True |


You will notice that this is the first time that the concept of `revision` appears. See more about this further down.

### Add an API operation

Then add an API operation to the API:

```t
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

```bash
az apim api operation show --api-id example-api --operation-id acctest-operation  --resource-group apim-rg --service-name example-apim-toli-io --output table
```

### Add an API operation policy

Policies in APIM are written in XML. You can find the documentation [here](https://docs.microsoft.com/en-us/azure/api-management/api-management-policies). And you can learn more about them [here](https://docs.microsoft.com/en-us/azure/api-management/api-management-howto-policies). You can add policies to [a number of scopes](https://docs.microsoft.com/en-us/azure/api-management/api-management-policies):

- Global
- Workspace
- Product
- API
- Operation

As an example, add a policy to the API operation:

```t
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

To create a new revision of an API using `az cli`, run:

```bash
az apim api revision create --api-id example-api --resource-group apim-rg --service-name example-apim-toli-io --api-revision 2 --api-revision-description "New revision"
```

This doesn't actually make it live, this adds a revision that's not current. You can check it's not current by running:

```bash
az apim api revision list --api-id example-api --resource-group apim-rg --service-name example-apim-toli-io --output json | jq '.[] | .apiRevision' | sort -V | tail -n 1
```


**Note**: revisions is a different concept to "versions". You can have multiple revisions of an API, but only one version. You can't have multiple versions of an API.

#### Updating the policy of a revision

To update a policy for a revision, you can't use `az cli`, or `terraform azurerm provider`. You will either have to use the Azure Portal or the Azure API Management REST API. Alternatively, you could [use Powershell](https://learn.microsoft.com/en-us/powershell/module/az.apimanagement/set-azapimanagementpolicy?view=azps-10.3.0).

For Powershell, run:

```powershell
$apimContext = New-AzApiManagementContext -ResourceGroupName "apim-rg" -ServiceName "example-apim-toli-io"
$api = Get-AzApiManagementApi -Context $apimContext -ApiId "example-api"
echo $api.ApiRevision

Set-AzApiManagementPolicy -Context $apimContext -ApiId "example-api" -PolicyFilePath "policy.xml" -ApiRevision $api.ApiRevision
```

Check the policy is what you expect:

```powershell
Get-AzApiManagementPolicy -Context $apimContext -ApiId "example-api" -SaveAs "remotepolicy.xml" -ApiRevision $api.ApiRevision      
```

#### Releasing a revision

To release a revision, run:

```bash
az apim api release create --api-id example-api --resource-group apim-rg --service-name example-apim-toli-io --api-revision 6 --notes 'Testing revisions. Added new "test" operation.'
```

Then run the following to check the correct revision is current:

```bash
az apim api revision list --api-id example-api --resource-group apim-rg --service-name example-apim-toli-io --output table
```

### Using the azurerm terraform provider

You can't actually achieve the same by using the azurerm terraform provider.

Let's have a look.

You can check which revision is current by running:

```bash
az apim api revision list --api-id example-api --resource-group apim-rg --service-name example-apim-toli-io --output table
```

First, create a new revision of the API by setting the `revision` to 2 (assumming the previous version is 1):

```t
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

```bash
az apim api revision list --api-id example-api --resource-group apim-rg --service-name example-apim-toli-io --output table
```

This deletes all revisions and creates a single revision (revision 2):

```
ApiId                    ApiRevision    CreatedDateTime                   Description    IsCurrent    IsOnline    PrivateUrl    UpdatedDateTime
-----------------------  -------------  --------------------------------  -------------  -----------  ----------  ------------  --------------------------------
/apis/example-api;rev=2  2              2023-09-20T09:45:32.957000+00:00                 True         True        /             2023-09-20T09:45:32.970000+00:00
```

It's not currently possible to simply add a new revision to existing revisions.

See [GitHub issue](https://github.com/hashicorp/terraform-provider-azurerm/issues/12720) or the [feature request](https://github.com/hashicorp/terraform-provider-azurerm/issues/22544)


## Testing powershell scripts

You can test powershell scripts using [Pester](https://pester.dev/).

To install Pester, run:

```powershell
Install-Module -Name Pester -Force 
Import-Module Pester -PassThru
```

To run the tests, run:

```powershell
Invoke-Pester
```

Create a file called `test.ps1`:

```bash
touch test.ps1
```

```powershell
Describe "My Test" {
    It "Should be true" {
        $true | Should -Be $true
    }
}
```

Then run:

```powershell
Invoke-Pester
```