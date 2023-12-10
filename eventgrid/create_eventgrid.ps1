$location = "southcentralus"
$group = "functions"
$stgname = "laazfuncs1stg"
$funcappname = "laazfuncs1"
$planname = "laazfuncs1plan"
$functionname = "EventGridFunction"

func init --worker-runtime dotnet
func new --template "EventGridTrigger" --name "EventGridFunction"

az provider register --namespace Microsoft.EventGrid

az group create -l $location -n $group 
az storage account create -n $stgname -g $group -l $location --sku Standard_LRS --kind StorageV2
az appservice plan create -g $group -n $planname -l $location --sku S1
az functionapp create `
  --name $funcappname `
  --resource-group $group `
  --os-type Windows `
  --runtime dotnet `
  --plan $planname `
  --storage-account $stgname

# az functionapp config appsettings list -n $funcappname -g $group

# First do a KUDU login so we can get a JWT bearer token
#$user = $(az webapp deployment list-publishing-profiles -n $funcappname -g $group --query "[?publishMethod=='MSDeploy'].userName" -o tsv)
#$pass = $(az webapp deployment list-publishing-profiles -n $funcappname -g $group --query "[?publishMethod=='MSDeploy'].userPWD" -o tsv)

# Creating event grid subscription linked against the endpoint is an admin function so requires a master key
#masterKeyResponse=$(curl -s -H "Authorization: Bearer $bearerToken" "https://$appName.azurewebsites.net/admin/host/systemkeys/_master")
#masterKey=$(echo $masterKeyResponse | jq '.value' | tr -d '"')

dotnet build
func azure functionapp publish $funcappname --force

$user = $(az webapp deployment list-publishing-profiles -n $funcappname -g $group --query "[?publishMethod=='MSDeploy'].userName" -o tsv)
$pass = $(az webapp deployment list-publishing-profiles -n $funcappname -g $group --query "[?publishMethod=='MSDeploy'].userPWD" -o tsv)
$pair = "$($user):$($pass)"
$encodedCreds = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($pair))
$jwt = Invoke-RestMethod -Uri "https://$funcappname.scm.azurewebsites.net/api/functions/admin/token" `
                         -Headers @{Authorization=("Basic {0}" -f $encodedCreds)} -Method GET

$keys = Invoke-RestMethod -Method GET -Headers @{Authorization=("Bearer {0}" -f $jwt)} `
            -Uri "https://$funcappname.azurewebsites.net/admin/functions/$functionname/keys" 
$key = $keys.keys[0].value
$key

#az eventgrid event-subscription list -l $location -g $group
#az eventgrid event-subscription delete --name blobcreatedsub

$evtgridsubname = "blobcreatedsub"
$subid = az account show --query 'id' -o tsv

$sourceid = "/subscriptions/$subid/resourceGroups/functions/providers/Microsoft.Storage/StorageAccounts/$stgname/providers/Microsoft.EventGrid/eventSubscriptions/$evtgridsubname"
$sourceid

#$sourceid = "/subscriptions/$subid/resourceGroups/functions/providers/Microsoft.Storage/StorageAccounts/$funcappname/providers/Microsoft.EventGrid/eventSubscriptions/blobcreatedsub"

$endpoint = "https://$funcappname.azurewebsites.net/runtime/webhooks/eventgrid?FunctionName=$functionname&code=$key"
$endpoint

#$sourceid = "/subscriptions/298c6f7d-4dac-465f-b7e4-65e216d1dbe9/resourceGroups/functions/providers/Microsoft.Storage/StorageAccounts/laazfuncs1stg/providers/Microsoft.EventGrid/eventSubscriptions/blobcreatedsub"
$storageid = $(az storage account show --name $stgname --resource-group $group --query id --output tsv)
$storageid

az eventgrid event-subscription create `
  --source-resource-id $storageid `
  --included-event-types Microsoft.Storage.BlobCreated `
  --subject-begins-with "/blobServices/default/containers/images/blobs/" `
  --name $evtgridsubname `
  --endpoint-type webhook `
  --endpoint "$endpoint"

az eventgrid event-subscription list -l $location -g $group

