$location = "centralus"
$group = "functions"
$stgname = "funcsstg"
$funcappname = "laazfuncs1"
az group create -l $location --n $group 
az storage account create -n $funcsstg -g $group -l $location --sku Standard_LRS
az functionapp create `
  --consumption-plan-location $location `
  --name $funcappname `
  --os-type Windows `
  --resource-group functions `
  --runtime dotnet `
  --storage-account funcsstg 

$funcappname = "laazfuncs2"
func azure functionapp publish $funcappname

az functionapp config appsettings set --name $funcappname -g $group --settings MySetting=Remote
