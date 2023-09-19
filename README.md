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
