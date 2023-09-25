# Update the current revision with the new policy
# Usage: UpdateNewRevisionPolicy.ps1 -resourceGroupName <resource group name> -serviceName <service name> -apiId <api id> -apiRevision <api revision> -policyFilePath <policy file path>

$apimContext = New-AzApiManagementContext -ResourceGroupName "apim-rg" -ServiceName "example-apim-toli-io"
$api = Get-AzApiManagementApi -Context $apimContext -ApiId "example-api"
Write-Output $api.ApiRevision

# get current revision number
$latestRevision = $(az apim api revision list --api-id $apiId --resource-group $resourceGroupName --service-name $serviceName --output json | jq '.[] | select(.isCurrent == false) | .apiRevision' | sort -V | tail -n 1).Replace('"', '')
$latestCurrentRevision = $(az apim api revision list --api-id $apiId --resource-group $resourceGroupName --service-name $serviceName --output json | jq '.[] | select(.isCurrent == true) | .apiRevision' | sort -V | tail -n 1).Replace('"', '')

# log error if we are not updating the latest revision
if ($latestRevision -ne $latestCurrentRevision) {
    Write-Output "Error: You are not updating the latest revision. Please update the latest revision."
    exit 1
}

Write-Output "Latest revision: $latestRevision"
Write-Output "Latest current revision: $latestCurrentRevision"
Set-AzApiManagementPolicy -Context $apimContext -ApiId "example-api" -PolicyFilePath "policy.xml" -ApiRevision $latestRevision 