# Get the latest revision of the APIM API and create a new revision
# Usage: CreateNewRevision.ps1 -resourceGroupName <resource group name> -serviceName <service name> -apiId <api id> -apiRevision <api revision> -apiRevisionDescription <api revision description>

$latestRevision = $(az apim api revision list --api-id example-api --resource-group apim-rg --service-name example-apim-toli-io --output json | jq '.[] | .apiRevision' | sort -V | tail -n 1)
# convert to int

Write-Output "Latest revision: $($latestRevision)"
$latestRevision = [int]$latestRevision.Trim().Replace('"', '')
$newRevision = $latestRevision + 1
az apim api revision create --api-id example-api --resource-group apim-rg --service-name example-apim-toli-io --api-revision $newRevision --api-revision-description "New revision"
