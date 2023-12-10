az login

$funcappname = $(az functionapp list --query "[0].name" -o tsv)
$funcappname

$group = $(az group list --query "[0].name" -o tsv)
$group 

az functionapp deployment slot create --name $funcappname -g $group --slot production
az functionapp deployment slot create --name $funcappname -g $group --slot staging

# modify code (A)
dotnet clean
dotnet build

func azure functionapp publish $funcappname --force --csharp

# modify code (B)
dotnet clean
dotnet build

func azure functionapp publish $funcappname --slot staging --force --csharp

# swap B into prod, A into staging
az functionapp deployment slot swap -g $group -n $funcappname --slot staging --target-slot production 

# swap B into staging, A into prod
az functionapp deployment slot swap -g $group -n $funcappname --slot staging --target-slot production 
